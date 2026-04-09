# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X111Wrapper
from sympy import Integer, floor, exp
from X216_test import oneX216

maxX111 = (1 << 255) - 1
minX111 = 0 - (1 << 255)
oneX111 = 1 << 111
minusOneX127 = 0 - (1 << 111)
maxGrowth = (1 << 127)

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X111Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_min(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.minX111(value0, value1)
    result = tx.return_value
    assert result == min(value0, value1)

@pytest.mark.parametrize('value0', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
@pytest.mark.parametrize('value1', [minX111, minX111 // 3, 0, maxX111 // 3, maxX111])
def test_max(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxX111(value0, value1)
    result = tx.return_value
    assert result == max(value0, value1)

@pytest.mark.parametrize('value0', [oneX111, oneX111 + (maxGrowth - oneX111) // 3, oneX111 + (2 * (maxGrowth - oneX111)) // 3, maxGrowth])
@pytest.mark.parametrize('value1', [0, 1 << 64, (1 << 127) - 1])
def test_timesUnsigned(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.timesUnsigned(value0, value1)
    result = tx.return_value
    assert result == value0 * value1

@pytest.mark.parametrize('value0', [oneX111, oneX111 + (maxGrowth - oneX111) // 3, oneX111 + (2 * (maxGrowth - oneX111)) // 3, maxGrowth])
@pytest.mark.parametrize('value1', [1 - (1 << 127), 0 - (1 << 64), 0, 1 << 64, (1 << 127) - 1])
def test_timesSigned(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.timesSigned(value0, value1)
    result = tx.return_value
    assert result == value0 * value1

@pytest.mark.parametrize('value0', [oneX111, oneX111 + (maxGrowth - oneX111) // 3, oneX111 + (2 * (maxGrowth - oneX111)) // 3, maxGrowth])
@pytest.mark.parametrize('value1', [0, oneX216 // 5, oneX216 // 3, oneX216])
def test_mulDivByExpInv8(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mulDivByExpInv8(value0, value1)
    result = tx.return_value
    assert result == floor(Integer(value0 * value1) / ((2 ** 119) * exp(-8)))