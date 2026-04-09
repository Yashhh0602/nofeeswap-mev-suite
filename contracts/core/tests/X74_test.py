# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X74Wrapper

maxX74 = (1 << 113) - 1
minX74 = 0 - (1 << 113)
oneX74 = 1 << 74

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X74Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
@pytest.mark.parametrize('value1', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
@pytest.mark.parametrize('value1', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
@pytest.mark.parametrize('value1', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
@pytest.mark.parametrize('value1', [minX74, minX74 // 3, 0, maxX74 // 3, maxX74])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)

@pytest.mark.parametrize('value', [minX74, minX74 // 3, minX74 // 5, 0, maxX74 // 5, maxX74 // 3, maxX74])
def test_timesUnsigned(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.toX216(value)
    result = tx.return_value
    assert result == (1 << 142) * value