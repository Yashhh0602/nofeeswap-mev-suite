# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, PoolIdWrapper
from Nofee import logTest, address0, toInt, twosComplementInt8

address1 = '0x0000000000000000000000000000000000000001'
address2 = '0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F'
address3 = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return PoolIdWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('offset', range(-89, 90, 5))
@pytest.mark.parametrize('hook', [address0])
@pytest.mark.parametrize('value', [value0, value1, value2, value3])
def test_getLogOffsetFromPoolId(wrapper, offset, hook, value, request, worker_id):
    logTest(request, worker_id)
    
    poolId = ((value & ((2 ** 68) - 1)) << 188) + (twosComplementInt8(offset) << 180) + toInt(hook)
    tx = wrapper._getLogOffsetFromPoolId(poolId)
    result = tx.return_value
    assert result == offset * (1 << 59)