# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, IndexWrapper

maxIndex = (1 << 16) - 1

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return IndexWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_equals(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.equals(index0, index1)
    assert tx.return_value == (index0 == index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_notEqual(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.notEqual(index0, index1)
    assert tx.return_value == (index0 != index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_lessThan(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThan(index0, index1)
    assert tx.return_value == (index0 < index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_greaterThan(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThan(index0, index1)
    assert tx.return_value == (index0 > index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_lessThanOrEqualTo(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.lessThanOrEqualTo(index0, index1)
    assert tx.return_value == (index0 <= index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_greaterThanOrEqualTo(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.greaterThanOrEqualTo(index0, index1)
    assert tx.return_value == (index0 >= index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_add(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(index0, index1)
    assert tx.return_value == (index0 + index1) % (2 ** 256)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_sub(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(index0, index1)
    assert tx.return_value == (index0 - index1) % (2 ** 256)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_min(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.minIndex(index0, index1)
    result = tx.return_value
    assert result == min(index0, index1)

@pytest.mark.parametrize('index0', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
@pytest.mark.parametrize('index1', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_max(wrapper, index0, index1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.maxIndex(index0, index1)
    result = tx.return_value
    assert result == max(index0, index1)

@pytest.mark.parametrize('index', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_getIndex(wrapper, index, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.getIndex(index)
    assert tx.return_value == index

@pytest.mark.parametrize('index', [0, maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex - 1])
def test_incrementIndex(wrapper, index, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.incrementIndex(index)
    assert tx.return_value == index + 1

@pytest.mark.parametrize('index', [maxIndex // 7, maxIndex // 5, maxIndex // 3, maxIndex])
def test_decrementIndex(wrapper, index, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.decrementIndex(index)
    assert tx.return_value == index - 1