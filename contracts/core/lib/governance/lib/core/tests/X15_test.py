# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X15Wrapper

oneX15 = 2 ** 15

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X15Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
@pytest.mark.parametrize('value1', [0, oneX15 // 5, oneX15 // 4, oneX15 // 3, oneX15 // 2, oneX15])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)