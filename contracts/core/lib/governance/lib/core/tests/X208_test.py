# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X208Wrapper
from sympy import Integer, floor, exp
from X216_test import maxX216, oneX216

maxX208 = 2 ** 256 - 1
oneX208 = 2 ** 208

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X208Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    if value0 + value1 <= maxX208:
        assert result == value0 + value1

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    if value0 >= value1:
        assert result == value0 - value1

@pytest.mark.parametrize('value', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('numerator', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator', [oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_mulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if (value * numerator) // denominator < 2 ** 256:
        tx = wrapper.mulDiv(value, numerator, denominator)
        result = tx.return_value
        assert result == (value * numerator) // denominator

@pytest.mark.parametrize('value0', [0, oneX208 // 5, oneX208 // 3, oneX208, maxX208 // 5, maxX208 // 3, maxX208])
@pytest.mark.parametrize('value1', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_mulDivByExpInv8(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mulDivByExpInv8(value0, value1)
    result = tx.return_value
    assert result == floor(Integer(value0 * value1) / ((2 ** 313) * exp(-8)))