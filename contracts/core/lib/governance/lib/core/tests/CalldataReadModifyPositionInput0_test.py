# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, CalldataWrapper
from eth_abi import encode
from Nofee import logTest, _shares_, _logPriceMinOffsetted_, _logPriceMaxOffsetted_, _logPriceMin_, _logPriceMax_, _hookData_, _hookDataByteCount_, _hookInputByteCount_, _freeMemoryPointer_, _msgSender_, _poolId_, _endOfStaticParams_, _curve_, toInt, twosComplementInt8, twosComplement

maxCurveIndex = 0xFFFF
maxKernelIndex = 1020
maxHookDataByteCount = 0xFFFF

zeroForOne0 = 0
zeroForOne1 = 1
zeroForOne2 = 2
zeroForOne3 = 3
zeroForOne4 = 4

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

portion0 = 0x000000000000
portion1 = 0x400000000000
portion2 = 0x800000000000
portion3 = 0xFFFFFFFFFFFF

balance0 = 0x00000000000000000000000000000000
balance1 = 0x00000000000000000000000000000001
balance2 = 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance3 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance5 = 0 - 0x00000000000000000000000000000001
balance6 = 0 - 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance7 = 0 - 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance8 = 0 - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF
logPrice5 = 0x10000000000000000

poolId0 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(-89) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId1 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(-8 ) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId2 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+0 ) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId3 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+8 ) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId4 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+89) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F

poolId0Invalid = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(-90) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId1Invalid = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+90) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return CalldataWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('logPrices', [[logPrice1, logPrice2], [logPrice1, logPrice3], [logPrice2, logPrice3]])
@pytest.mark.parametrize('shares', [balance1, balance3, balance5, balance7])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('hookDataByteCount', [0, maxHookDataByteCount // 2, maxHookDataByteCount])
def test_readModifyPositionInput(wrapper, poolId, logPrices, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qMin = min(logPrices)
    qMax = max(logPrices)

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    logPriceMin = qMin + (qOffset * (1 << 59)) - (1 << 63)
    logPriceMax = qMax + (qOffset * (1 << 59)) - (1 << 63)
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 5 * 0x20 + gap

    calldata = wrapper._readModifyPositionInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMin).to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMax).to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    memoryContent = tx.events[0]['data']

    assert memoryContent[_msgSender_ : _msgSender_ + 20].hex() == root.address.lower()[2:]
    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == poolId
    assert toInt(memoryContent[_logPriceMin_ : _logPriceMin_ + 32].hex()) == twosComplement(logPriceMin)
    assert toInt(memoryContent[_logPriceMax_ : _logPriceMax_ + 32].hex()) == twosComplement(logPriceMax)
    assert toInt(memoryContent[_logPriceMinOffsetted_ : _logPriceMinOffsetted_ + 8].hex()) == qMin
    assert toInt(memoryContent[_logPriceMaxOffsetted_ : _logPriceMaxOffsetted_ + 8].hex()) == qMax
    assert toInt(memoryContent[_shares_ : _shares_ + 32].hex()) == twosComplement(shares)

    hookDataByteCount = len(hookDataBytes) - 32
    hookInputByteCount = _endOfStaticParams_ + 32 + hookDataByteCount - _hookInputByteCount_ - 32

    curvePlacement = _endOfStaticParams_
    hookDataPlacement = curvePlacement + 32
    freeMemoryPointer = hookDataPlacement + hookDataByteCount

    assert toInt(memoryContent[_curve_ : _curve_ + 32].hex()) == curvePlacement
    assert toInt(memoryContent[_hookData_ : _hookData_ + 32].hex()) == hookDataPlacement
    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer

    assert toInt(memoryContent[_hookDataByteCount_ : _hookDataByteCount_ + 2].hex()) == hookDataByteCount
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount

    assert memoryContent[hookDataPlacement : hookDataPlacement + hookDataByteCount] == hookDataBytes[32:]