# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X47Wrapper

oneX47 = 2 ** 47

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X47Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_min(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.minX47(value0, value1)
    result = tx.return_value
    assert result == min(value0, value1)

@pytest.mark.parametrize('value0', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('value1', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_max(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxX47(value0, value1)
    result = tx.return_value
    assert result == max(value0, value1)