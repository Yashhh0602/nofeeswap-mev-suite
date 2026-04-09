# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, StorageWrapper
from Nofee import logTest

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

@pytest.mark.parametrize('poolId', [value0, value4])
@pytest.mark.parametrize('content0', [value0, value1, value2, value4])
@pytest.mark.parametrize('content1', [value0, value1, value2, value4])
@pytest.mark.parametrize('content2', [value0, value1, value2, value4])
@pytest.mark.parametrize('content3', [value0, value1, value2, value4])
def test_readDynamicParams(wrapper, poolId, content0, content1, content2, content3, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to dynamic parameters are read correctly.
    _staticParamsStoragePointerExtension = content3
    _staticParamsStoragePointer = (content0 >> (256 - 16)) % (1 << 16)
    _logPriceCurrent = (content0 >> (256 - 16 - 64)) % (1 << 64)
    _sharesTotal = (content0 >> (256 - 16 - 64 - 128)) % (1 << 128)
    _growth_1 = (content0 >> (256 - 16 - 64 - 128 - 48)) % (1 << 48)
    _growth_0 = (content1 >> (256 - 80)) % (1 << 80)
    _growth = (_growth_1 << 80) + _growth_0
    _integral0_1 = (content1 >> (256 - 80 - 176)) % (1 << 176)
    _integral0_0 = (content2 >> (256 - 40)) % (1 << 40)
    _integral0 = (_integral0_1 << 40) + _integral0_0
    _integral1 = (content2 >> (256 - 40 - 216)) % (1 << 216)

    if _growth != 0:
        tx = wrapper._readDynamicParams(poolId, content0, content1, content2, content3)
        staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = tx.return_value
        if _staticParamsStoragePointer == 0xFFFF:
            assert staticParamsStoragePointerExtension == _staticParamsStoragePointerExtension
        else:
            assert staticParamsStoragePointerExtension == _staticParamsStoragePointer
        assert staticParamsStoragePointer == _staticParamsStoragePointer
        assert logPriceCurrent == _logPriceCurrent
        assert sharesTotal == _sharesTotal
        assert growth == _growth
        assert integral0 == _integral0
        assert integral1 == _integral1
    else:
        with brownie.reverts('PoolDoesNotExist: ' + str(poolId)):
            tx = wrapper._readDynamicParams(poolId, content0, content1, content2, content3)