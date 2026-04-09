# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, TagWrapper
from Nofee import logTest, address0, toInt, keccak, keccakPacked
from X59_test import oneX59, maxX59

address1 = '0x0000000000000000000000000000000000000001'
address2 = '0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F'
address3 = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'

id0 = 0x0000000000000000000000000000000000000000000000000000000000000000
id1 = 0x0000000000000000000000000000000000000000000000000000000000000001
id2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
id3 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

tag0 = 0x0000000000000000000000000000000000000000000000000000000000000000
tag1 = 0x0000000000000000000000000000000000000000000000000000000000000001
tag2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
tag3 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

poolId0 = 0x0000000000000000000000000000000000000000000000000000000000000001
poolId1 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
poolId2 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return TagWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('value1', [tag0, tag1, tag2, tag3])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    assert tx.return_value == (value0 == value1)

@pytest.mark.parametrize('value0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('value1', [tag0, tag1, tag2, tag3])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    assert tx.return_value == (value0 != value1)

@pytest.mark.parametrize('value0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('value1', [tag0, tag1, tag2, tag3])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    assert tx.return_value == (value0 <= value1)

@pytest.mark.parametrize('value0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('value1', [tag0, tag1, tag2, tag3])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    assert tx.return_value == (value0 >= value1)

@pytest.mark.parametrize('value0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('value1', [tag0, tag1, tag2, tag3])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    assert tx.return_value == (value0 <= value1)

@pytest.mark.parametrize('value0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('value1', [tag0, tag1, tag2, tag3])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    assert tx.return_value == (value0 >= value1)

@pytest.mark.parametrize('account', [address0, address1, address2, address3])
def test_tag0(wrapper, account, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.tag(account)
    assert tx.return_value == toInt(account)

@pytest.mark.parametrize('account', [address0, address1, address2, address3])
@pytest.mark.parametrize('id', [id0, id1, id2, id3])
def test_tag1(wrapper, account, id, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.tag(account, id)
    assert tx.return_value == keccakPacked(['uint256', 'address'], [id, account])

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2])
@pytest.mark.parametrize('logPriceMin', [0, oneX59 // 5, oneX59 // 3, oneX59, maxX59 // 5, maxX59 // 3, maxX59 // 5, maxX59 // 3, maxX59])
@pytest.mark.parametrize('logPriceMax', [0, oneX59 // 5, oneX59 // 3, oneX59, maxX59 // 5, maxX59 // 3, maxX59 // 5, maxX59 // 3, maxX59])
def test_tag2(wrapper, poolId, logPriceMin, logPriceMax, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.tag(poolId, logPriceMin, logPriceMax)
    assert tx.return_value == keccak(['uint256', 'int256', 'int256'], [poolId, logPriceMin, logPriceMax])