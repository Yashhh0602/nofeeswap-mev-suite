# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, X23Wrapper

oneX23 = 2 ** 23

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return X23Wrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', [0, oneX23 // 5, oneX23 // 3, oneX23])
@pytest.mark.parametrize('value1', [0, oneX23 // 5, oneX23 // 3, oneX23])
def test_add(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.add(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 + value1) % (2 ** 256)

@pytest.mark.parametrize('value0', [0, oneX23 // 5, oneX23 // 3, oneX23])
@pytest.mark.parametrize('value1', [0, oneX23 // 5, oneX23 // 3, oneX23])
def test_sub(wrapper, value0, value1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sub(value0, value1)
    result = tx.return_value
    assert result % (2 ** 256) == (value0 - value1) % (2 ** 256)