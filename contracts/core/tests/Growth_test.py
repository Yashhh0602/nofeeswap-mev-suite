# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from Nofee import logTest
from brownie import accounts, GrowthWrapper
from sympy import Integer, floor

list0X111 = [((1 << 127) - 1) // 5, ((1 << 127) - 1) // 3, ((1 << 127) - 1)]

oneX47 = 2 ** 47
listX47 = [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47]

list1X216 = [((1 << 216) - 1) // 3, ((1 << 216) - 1)]

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return GrowthWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('value0', list0X111 + [0])
@pytest.mark.parametrize('value1', listX47 + [0])
@pytest.mark.parametrize('value2', listX47 + [0])
@pytest.mark.parametrize('value3', list1X216 + [0])
@pytest.mark.parametrize('value4', list1X216)
def test_update(wrapper, value0, value1, value2, value3, value4, request, worker_id):
    logTest(request, worker_id)
    
    value = floor(value0 + Integer(value0 * (oneX47 - value1) * (oneX47 - value2) * value3) / (value4 << 94))
    if value <= (1 << 127):
        tx = wrapper.updateGrowthWrapper(value0, value1, value2, value3, value4)
        result = tx.return_value
        assert result == value
    else:
        with brownie.reverts():
            wrapper.updateGrowthWrapper(value0, value1, value2, value3, value4)