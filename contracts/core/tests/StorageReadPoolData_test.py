# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, StorageWrapper
from sympy import ceiling
from eth_abi import encode
from Nofee import logTest, _hookInputByteCount_, _freeMemoryPointer_, _poolGrowthPortion_, _dynamicParams_, _pendingKernelLength_, _staticParams_, _endOfStaticParams_, toInt, keccakPacked, encodeCurve

accruedMax = (1 << 231) - 1

address1 = '0x0000000000000000000000000000000000000001'
address2 = '0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F'
address3 = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'

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
balance3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance5 = 0 - 0x00000000000000000000000000000001
balance6 = 0 - 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance7 = 0 - 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance8 = 0 - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

storageSlot0 = 0x0000000000000000000000000000000000000000000000000000000000000000
storageSlot1 = 0x0000000000000000000000000000000000000000000000000000000000000001
storageSlot2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
storageSlot3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
storageSlot4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

ratio0 = 0x000000
ratio1 = 0x400000
ratio2 = 0x800000
ratio3 = 0xFFFFFF

accrued0 = 0x0000000000000000000000000000000000000000000000000000000000000000
accrued1 = 0x0000000000000000000000000000000080000000000000000000000000000000
accrued2 = 0x7807F807F807F807F807F807F807F80780000000000000000000000000000000
accrued3 = 0x47FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000000000000000000000000000
accrued4 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000000000000000000000000000

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF

pointer0 = 0x0000
pointer1 = 0xF00F
pointer2 = 0xFFFF

integral0 = 0x000000000000000000000000000000000000000000000000000000
integral1 = 0xFFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
integral2 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

curve0 = 0x0550550550550550550550550550550550550550550550550550550550550550
curve1 = 0x1001001001001001001001001001001001001001001001001001001001001001
curve2 = 0x7CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC7
curve3 = 0x8BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB8
curve4 = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return StorageWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('poolId', [value0, value2])
@pytest.mark.parametrize('kernelLength', [2, 10, 25])
@pytest.mark.parametrize('kernelPendingLength', [2, 10, 25])
@pytest.mark.parametrize('curveLength', [2, 10, 25])
@pytest.mark.parametrize('storagePointerExtension', [False])
@pytest.mark.parametrize('dynamicContent', [value0, value2])
@pytest.mark.parametrize('curve', [curve0, curve2])
@pytest.mark.parametrize('content', [value2, value3, value4])
@pytest.mark.parametrize('kernel', [_endOfStaticParams_, _endOfStaticParams_ + 200])
def test_readPoolData(poolId, kernelLength, kernelPendingLength, curveLength, storagePointerExtension, dynamicContent, curve, content, kernel, request, worker_id):
    logTest(request, worker_id)
    
    # Check if pool data are read correctly.

    wrapper = StorageWrapper.deploy({'from': accounts[0]})

    staticParamsStoragePointerExtension = keccakPacked(
        ['uint256', 'uint256', 'uint256', 'uint256', 'bool', 'uint256', 'uint256', 'uint256', 'uint256'],
        [poolId, kernelLength, kernelPendingLength, curveLength, storagePointerExtension, dynamicContent, curve, content, kernel]
    )

    if storagePointerExtension:
        staticParamsStoragePointer = 0xFFFF
        content3 = staticParamsStoragePointerExtension
    else:
        staticParamsStoragePointer = staticParamsStoragePointerExtension % 0xFFFF
        staticParamsStoragePointerExtension = staticParamsStoragePointer
        content3 = 0

    logPriceCurrent = dynamicContent % (1 << 64)
    logPriceCurrent = 1 if logPriceCurrent == 0 else logPriceCurrent

    content0 = (staticParamsStoragePointer << (256 - 16)) + (logPriceCurrent << (256 - 16 - 64)) + (dynamicContent % (1 << (256 - 16 - 64)))
    if (content0 % (1 << (256 - 16 - 64)) == 0):
        content0 += 1
    content1 = dynamicContent
    content2 = dynamicContent

    _curve = [curve >> 192, (curve >> 128) % (1 << 64), (curve >> 64) % (1 << 64), curve % (1 << 64)] * ceiling(curveLength / 4)
    _curve = _curve[0:(curveLength - 1)] + [logPriceCurrent]
    curveArray = encodeCurve(_curve)

    contentLength = 64 * (kernelLength - 1) + (_endOfStaticParams_ - _staticParams_)
    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]

    contentBytes = contentBytes[0 : _pendingKernelLength_ - _staticParams_] + kernelPendingLength.to_bytes(2, 'big') + contentBytes[_pendingKernelLength_ - _staticParams_ + 2 : ]

    tx0 = wrapper._readPoolData0(
        poolId,
        kernelLength,
        staticParamsStoragePointerExtension,
        [content0, content1, content2, content3],
        curveArray,
        contentBytes
    )

    tx1 = wrapper._readPoolData1(poolId, kernel)

    result = tx1.return_value

    _content0 = toInt(result[_dynamicParams_ - 00: _dynamicParams_ + 32].hex())
    _content1 = toInt(result[_dynamicParams_ + 32: _dynamicParams_ + 64].hex())
    _content2 = toInt(result[_dynamicParams_ + 64: _dynamicParams_ + 96].hex())
    _content3 = toInt(result[_dynamicParams_ - 32: _dynamicParams_ - 00].hex())

    assert _content0 == content0
    assert _content1 == content1
    assert _content2 == content2
    assert _content3 == staticParamsStoragePointerExtension

    staticParams = result[_staticParams_ - 32: _endOfStaticParams_ - 32].hex() + result[kernel - 32: kernel + 64 * (kernelLength - 1) - 32].hex()

    if toInt(contentBytes[_poolGrowthPortion_ - _staticParams_ : _poolGrowthPortion_ - _staticParams_ + 6].hex()) > toInt(contentBytes[_poolGrowthPortion_ - _staticParams_ + 6 : _poolGrowthPortion_ - _staticParams_ + 12].hex()):
        contentBytes = contentBytes[0 : _poolGrowthPortion_ - _staticParams_] + contentBytes[_poolGrowthPortion_ - _staticParams_ + 6 : _poolGrowthPortion_ - _staticParams_ + 12] + contentBytes[_poolGrowthPortion_ - _staticParams_ + 6 : ]

    assert staticParams == contentBytes.hex()

    curvePointer = kernel + 64 * (max(kernelLength, kernelPendingLength) - 1)

    curveMemory = toInt(result[curvePointer - 32: curvePointer - 32 + 8 * curveLength].hex())
    if curveLength % 4 == 3:
        curveMemory = curveMemory << 64
    if curveLength % 4 == 2:
        curveMemory = curveMemory << 128
    if curveLength % 4 == 1:
        curveMemory = curveMemory << 192

    for kk in range(len(curveArray) - 1, -1, -1):
        assert curveArray[kk] == curveMemory % (1 << 256)
        curveMemory = curveMemory >> 256
        
    freeMemoryPointer = curvePointer + ((((curveLength - 1) >> 2) + 2) << 5)
    assert toInt(result[_freeMemoryPointer_ - 32 : _freeMemoryPointer_ + 32 - 32].hex()) == freeMemoryPointer
    assert toInt(result[_hookInputByteCount_ - 32 : _hookInputByteCount_ + 32 - 32].hex()) == freeMemoryPointer - _hookInputByteCount_ - 32