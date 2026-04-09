# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X216Wrapper
from sympy import Integer, floor, exp

maxX216 = (1 << 255) - 1
minX216 = 0 - (1 << 255)
oneX216 = 1 << 216
minusOneX216 = 0 - (1 << 216)

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X216Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [1 + minX216, minX216 // 3, minusOneX216, minusOneX216 // 5, 0, oneX216 // 5, oneX216, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minusOneX216, minusOneX216 // 3, minusOneX216 // 5, 0, oneX216 // 5, oneX216 // 3, oneX216])
def test_mul(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mul(value0, value1)
    result = tx.return_value
    if value0 * value1 >= 0:
        assert result == (value0 * value1) // (2 ** 216)
    else:
        assert abs(result - (- abs(value0) * abs(value1)) // (2 ** 216)) <= 1

@pytest.mark.parametrize('value0', [0, oneX216 // 5, oneX216 // 3, oneX216])
@pytest.mark.parametrize('value1', [0, oneX216 // 11, oneX216 // 9, oneX216 // 7])
def test_cheapMul(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.cheapMul(value0, value1)
    result = tx.return_value
    assert result == (value0 * value1) // (2 ** 216)

maxExpInv8 = floor(((maxX216 * oneX216) * exp(-8)) / (oneX216 - 1))

@pytest.mark.parametrize('value0', [0, oneX216 // 5, oneX216 // 3, oneX216 - 1])
@pytest.mark.parametrize('value1', [0, maxExpInv8 // 5, maxExpInv8 // 3, maxExpInv8])
def test_mulDivByExpInv8(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mulDivByExpInv8(value0, value1)
    result = tx.return_value
    assert result == floor(Integer(value0 * value1) / ((2 ** 216) * exp(-8)))

@pytest.mark.parametrize('value0', [0, oneX216 // 5, oneX216 // 3, oneX216 - 1])
@pytest.mark.parametrize('value1', [0, oneX216 // 5, oneX216 // 3, oneX216 - 1])
def test_mulDivByExpInv16(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mulDivByExpInv16(value0, value1)
    result = tx.return_value
    assert result == floor(Integer(value0 * value1) / ((2 ** 216) * exp(-16)))

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_min(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.minX216(value0, value1)
    result = tx.return_value
    assert result == min(value0, value1)

@pytest.mark.parametrize('value0', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
@pytest.mark.parametrize('value1', [minX216, minX216 // 3, 0, maxX216 // 3, maxX216])
def test_max(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxX216(value0, value1)
    result = tx.return_value
    assert result == max(value0, value1)

@pytest.mark.parametrize('numerator0', [0, oneX216 // 5, oneX216, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator0', [0, oneX216 // 5, oneX216, maxX216 // 3, maxX216])
@pytest.mark.parametrize('numerator1', [0, oneX216 // 5, oneX216, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator1', [0, oneX216 // 5, oneX216, maxX216 // 3, maxX216])
def test_minFractions(wrapper, numerator0, denominator0, numerator1, denominator1, request, worker_id):
    logTest(request, worker_id)
    
    if denominator0 != 0 or denominator1 != 0:
        tx = wrapper.minFractionsX216(numerator0, denominator0, numerator1, denominator1)
        numerator, denominator, overflow = tx.return_value
        if denominator0 == 0 and numerator0 == 0:
            assert numerator == numerator1
            assert denominator == denominator1
        elif denominator1 == 0 and numerator1 == 0:
            assert numerator == numerator0
            assert denominator == denominator0
        elif numerator0 * denominator1 <= numerator1 * denominator0:
            assert numerator == numerator0
            assert denominator == denominator0
        else:
            assert numerator == numerator1
            assert denominator == denominator1

maxX216overExpEpsilon = floor(maxX216 / exp(Integer(1) / (2 ** 60)))

@pytest.mark.parametrize('value', [0, maxX216overExpEpsilon // 5, maxX216overExpEpsilon // 3, maxX216overExpEpsilon])
def test_multiplyByExpEpsilon(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.multiplyByExpEpsilonX216(value)
    result = tx.return_value
    assert abs(result - floor(value * exp(Integer(1) / (2 ** 60) ))) <= 1

@pytest.mark.parametrize('value', [0, maxX216 // 5, maxX216 // 3, maxX216])
def test_divideByExpEpsilon(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.divideByExpEpsilonX216(value)
    result = tx.return_value
    assert abs(result - floor(Integer(value) / exp(Integer(1) / (2 ** 60) ))) <= 1

@pytest.mark.parametrize('value', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('numerator', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator', [oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_mulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if (value * numerator) // denominator < 2 ** 255:
        tx = wrapper.mulDiv(value, numerator, denominator)
        result = tx.return_value
        assert result == (value * numerator) // denominator

@pytest.mark.parametrize('value', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('numerator', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator', [oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_cheapMulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if value * numerator < denominator * (denominator - 1):
        tx = wrapper.cheapMulDiv(value, numerator, denominator)
        result = tx.return_value
        assert result == (value * numerator) // denominator