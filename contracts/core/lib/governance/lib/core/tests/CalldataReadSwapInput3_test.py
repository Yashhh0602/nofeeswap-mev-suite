# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, CalldataWrapper
from eth_abi import encode
from Nofee import logTest, _zeroForOne_, _crossThreshold_, _logPriceLimit_, _amountSpecified_, _hookData_, _hookDataByteCount_, _hookInputByteCount_, _msgSender_, _poolId_, _kernel_, _endOfStaticParams_, toInt, twosComplementInt8, twosComplement

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

@pytest.mark.parametrize('poolId', [poolId3])
@pytest.mark.parametrize('amountSpecified', [balance0, balance1, balance2, balance3, balance4, balance5, balance6, balance7, balance8])
@pytest.mark.parametrize('qLimit', [logPrice2])
@pytest.mark.parametrize('zeroForOne', [zeroForOne0, zeroForOne1, zeroForOne2])
@pytest.mark.parametrize('crossThreshold', [balance2])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('hookDataByteCount', [0, maxHookDataByteCount // 2, maxHookDataByteCount])
def test_readSwapInput(wrapper, poolId, amountSpecified, qLimit, zeroForOne, crossThreshold, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    logPriceLimit = qLimit + (qOffset * (1 << 59)) - (1 << 63)
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 5 * 0x20 + gap

    calldata = wrapper._readSwapInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(amountSpecified).to_bytes(32, 'big').hex() + \
        twosComplement(logPriceLimit).to_bytes(32, 'big').hex() + \
        twosComplement((crossThreshold << 128) + zeroForOne).to_bytes(32, 'big').hex() + \
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
    assert toInt(memoryContent[_amountSpecified_ : _amountSpecified_ + 32].hex()) == twosComplement(max(min(amountSpecified, (1 << 127) - 1), 1 - (1 << 127)) * (1 << 127))
    assert toInt(memoryContent[_logPriceLimit_ : _logPriceLimit_ + 32].hex()) == twosComplement(logPriceLimit)
    assert toInt(memoryContent[_crossThreshold_ : _crossThreshold_ + 16].hex()) == min(crossThreshold, (1 << 127) - 1)
    assert toInt(memoryContent[_zeroForOne_ : _zeroForOne_ + 1].hex()) == zeroForOne

    hookDataByteCount = len(hookDataBytes) - 32
    hookInputByteCount = _endOfStaticParams_ + hookDataByteCount - _hookInputByteCount_ - 32

    hookDataPlacement = _endOfStaticParams_
    kernelPlacement = hookDataPlacement + hookDataByteCount

    assert toInt(memoryContent[_hookData_ : _hookData_ + 32].hex()) == hookDataPlacement
    assert toInt(memoryContent[_hookDataByteCount_ : _hookDataByteCount_ + 2].hex()) == hookDataByteCount
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount
    assert toInt(memoryContent[_kernel_ : _kernel_ + 32].hex()) == kernelPlacement

    assert memoryContent[hookDataPlacement : hookDataPlacement + hookDataByteCount] == hookDataBytes[32:]