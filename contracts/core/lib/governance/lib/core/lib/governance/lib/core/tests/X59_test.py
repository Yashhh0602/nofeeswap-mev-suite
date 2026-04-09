# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X59Wrapper
from sympy import Integer, floor, exp, ceiling
from X216_test import maxX216, oneX216

maxX59 = (1 << 255) - 1
minX59 = 0 - (1 << 255)
oneX59 = 1 << 59
thirtyTwoX59 = 1 << 64
epsilonX59 = 1
minLogOffsetX59 = 0 - (90 << 59)
maxLogOffsetX59 = (90 << 59)

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X59Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [maxX59 // 11, maxX59 // 9, maxX59 // 7, maxX59 // 5, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [maxX59 // 11, maxX59 // 9, maxX59 // 7, maxX59 // 5, maxX59 // 3, maxX59])
def test_mod(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mod(value0, value1)
    result = tx.return_value
    assert result == value0 % value1

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_min(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.minX59(value0, value1)
    result = tx.return_value
    assert result == min(value0, value1)

@pytest.mark.parametrize('value0', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
@pytest.mark.parametrize('value1', [minX59, minX59 // 3, 0, maxX59 // 3, maxX59])
def test_max(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxX59(value0, value1)
    result = tx.return_value
    assert result == max(value0, value1)

@pytest.mark.parametrize('value', [0, maxX59 // 5, maxX59 // 3, maxX59 // 5, maxX59 // 3, maxX59])
@pytest.mark.parametrize('numerator', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator', [oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_cheapMulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if value * numerator < denominator * (denominator - 1):
        tx = wrapper.cheapMulDiv(value, numerator, denominator)
        result = tx.return_value
        assert result == (value * numerator) // denominator

@pytest.mark.parametrize('value', [0, oneX59 // 5, oneX59 // 3, oneX59, maxX59 // 5, maxX59 // 3, maxX59 // 5, maxX59 // 3, maxX59])
@pytest.mark.parametrize('multiplier0', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('multiplier1', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_mulDivByExpInv16(wrapper, value, multiplier0, multiplier1, request, worker_id):
    logTest(request, worker_id)
    
    if value * multiplier0 * multiplier1 < maxX216 * floor((2 ** (216 + 59)) * exp(-16)):
        tx = wrapper.mulDivByExpInv16(value, multiplier0, multiplier1)
        result = tx.return_value
        assert result == (value * multiplier0 * multiplier1) // ceiling((2 ** 275) * exp(-16))

@pytest.mark.parametrize('value', range(thirtyTwoX59 - 100 * epsilonX59, thirtyTwoX59, epsilonX59))
def test_expHigh(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.exp(value)
    exponentialInverse, exponentialOverExp16 = tx.return_value
    assert abs(exponentialInverse - floor((2 ** 216) * exp(-Integer(value) / (2 ** 60)))) <= 1
    assert abs(exponentialOverExp16 - floor((2 ** 216) * exp(-16 + (Integer(value) / (2 ** 60))))) <= 1

@pytest.mark.parametrize('value', range(epsilonX59, 100 * epsilonX59, epsilonX59))
def test_expLow(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.exp(value)
    exponentialInverse, exponentialOverExp16 = tx.return_value
    assert abs(exponentialInverse - floor((2 ** 216) * exp(-Integer(value) / (2 ** 60)))) <= 1
    assert abs(exponentialOverExp16 - floor((2 ** 216) * exp(-16 + (Integer(value) / (2 ** 60))))) <= 1

@pytest.mark.parametrize('value', range(2 * maxLogOffsetX59 - 100 * epsilonX59, 2 * maxLogOffsetX59, epsilonX59))
def test_expOffsetHigh(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.expOffset(value)
    exponentialInverse = tx.return_value
    assert abs(exponentialInverse - floor((2 ** 256) * exp(-Integer(value) / (2 ** 60)))) <= 2 ** 60

@pytest.mark.parametrize('value', range(epsilonX59, 100 * epsilonX59, epsilonX59))
def test_expOffsetLow(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.expOffset(value)
    exponentialInverse = tx.return_value
    assert abs(exponentialInverse - floor((2 ** 256) * exp(-Integer(value) / (2 ** 60)))) <= 2 ** 60

@pytest.mark.parametrize('value', range(maxLogOffsetX59 - 100 * epsilonX59, maxLogOffsetX59, epsilonX59))
def test_logToSqrtOffsetHigh(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.logToSqrtOffset(value)
    sqrtOffset = tx.return_value
    assert abs(sqrtOffset - floor((2 ** 127) * exp(Integer(value) / (2 ** 60)))) <= 1

@pytest.mark.parametrize('value', range(minLogOffsetX59, minLogOffsetX59 + 100 * epsilonX59, epsilonX59))
def test_logToSqrtOffsetLow(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.logToSqrtOffset(value)
    sqrtOffset = tx.return_value
    assert abs(sqrtOffset - floor((2 ** 127) * exp(Integer(value) / (2 ** 60)))) <= 1

@pytest.mark.parametrize('value', range(- 100 * epsilonX59, + 100 * epsilonX59, epsilonX59))
def test_logToSqrtOffsetMid(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.logToSqrtOffset(value)
    sqrtOffset = tx.return_value
    assert abs(sqrtOffset - floor((2 ** 127) * exp(Integer(value) / (2 ** 60)))) <= 1