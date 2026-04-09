
# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from Nofee import logTest
from brownie import accounts, X127Wrapper
from X216_test import maxX216, oneX216

maxX127 = (1 << 255) - 1
minX127 = 0 - (1 << 255)
oneX127 = 1 << 127
minusOneX127 = 0 - (1 << 127)

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X127Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_equals(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(value0, value1)
    result = tx.return_value
    assert result == (value0 == value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_notEqual(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(value0, value1)
    result = tx.return_value
    assert result == (value0 != value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_lessThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(value0, value1)
    result = tx.return_value
    assert result == (value0 < value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_greaterThan(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(value0, value1)
    result = tx.return_value
    assert result == (value0 > value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_lessThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 <= value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_greaterThanOrEqualTo(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(value0, value1)
    result = tx.return_value
    assert result == (value0 >= value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_safeAdd(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    if (- 2 ** 255 <= value0 + value1 < 2 ** 255):
        tx = wrapper.safeAdd(value0, value1)
        result = tx.return_value
        assert result == value0 + value1
    else:
        with brownie.reverts('SafeAddFailed: ' + str(value0) + ', ' + str(value1)):
            wrapper.safeAdd(value0, value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_min(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.minX127(value0, value1)
    result = tx.return_value
    assert result == min(value0, value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_max(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxX127(value0, value1)
    result = tx.return_value
    assert result == max(value0, value1)

@pytest.mark.parametrize('value0', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
@pytest.mark.parametrize('value1', [minX127, minX127 // 3, 0, maxX127 // 3, maxX127])
def test_max(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxX127(value0, value1)
    result = tx.return_value
    assert result == max(value0, value1)

maxOverOneX23 = (1 << 233) - 1
oneX23 = 1 << 23

@pytest.mark.parametrize('value0', [0, maxOverOneX23 // 5, maxOverOneX23 // 3, maxOverOneX23])
@pytest.mark.parametrize('value1', [0, oneX23 // 5, oneX23 // 3, oneX23])
def test_times(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.times(value0, value1)
    result = tx.return_value
    assert result == (value0 * value1) // oneX23

@pytest.mark.parametrize('value', [0, oneX127 // 5, oneX127 // 3, maxX127 // 5, maxX127 // 3, maxX127])
@pytest.mark.parametrize('numerator', [0, oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
@pytest.mark.parametrize('denominator', [oneX216 // 5, oneX216 // 3, maxX216 // 5, maxX216 // 3, maxX216])
def test_mulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if (value * numerator) // denominator < 2 ** 255:
        tx = wrapper.mulDiv(value, numerator, denominator)
        result = tx.return_value
        assert result == (value * numerator) // denominator

@pytest.mark.parametrize('value', [minX127, minX127 // 3, minX127 // 5, minX127 // 7, minX127 // 9, maxX127 // 9, maxX127 // 7, maxX127 // 5, maxX127 // 3, maxX127])
def test_toInteger(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.toInteger(value)
    result = tx.return_value
    assert result == value // (2 ** 127)

@pytest.mark.parametrize('value', [1 + minX127, minX127 // 3, minX127 // 5, minX127 // 7, minX127 // 9, maxX127 // 9, maxX127 // 7, maxX127 // 5, maxX127 // 3, maxX127])
def test_toIntegerRoundUp(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.toIntegerRoundUp(value)
    result = tx.return_value
    assert result == 0 - ((0 - value) // (2 ** 127))