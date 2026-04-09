# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from Nofee import logTest
from brownie import accounts, GrowthPortionWrapper
from sympy import Integer, floor
from X23_test import oneX23
from X47_test import oneX47

accrued0 = 0x0000000000000000000000000000000000000000000000000000000000000000
accrued1 = 0x0000000000000000000000000000000080000000000000000000000000000000
accrued2 = 0x7807F807F807F807F807F807F807F80780000000000000000000000000000000
accrued3 = 0x47FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000000000000000000000000000
accrued4 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000000000000000000000000000

ratio0 = 0x000000
ratio1 = 0x400000
ratio2 = 0x800000
ratio3 = 0xFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return GrowthPortionWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('protocolGrowthPortion', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('poolGrowthPortion', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('increment', [accrued0, accrued1, accrued2, accrued3, accrued4])
@pytest.mark.parametrize('currentAccrued', [accrued0, accrued1, accrued2, accrued3, accrued4])
@pytest.mark.parametrize('currentPoolRatio', [ratio0, ratio1, ratio2, ratio3])
def test_calculateGrowthPortion(wrapper, protocolGrowthPortion, poolGrowthPortion, increment, currentAccrued, currentPoolRatio, request, worker_id):
    logTest(request, worker_id)
    
    _poolPortionIncrement = floor(Integer(increment * (oneX47 - protocolGrowthPortion) * poolGrowthPortion) / (oneX47 * oneX47))
    _updatedAccrued = floor(currentAccrued + _poolPortionIncrement + Integer(increment * protocolGrowthPortion) / oneX47)
    if _updatedAccrued == 0:
        _updatedPoolRatio = 0
    else:
        _updatedPoolRatio = floor(Integer(currentPoolRatio * currentAccrued + oneX23 * _poolPortionIncrement) / _updatedAccrued)

    if _updatedAccrued < (1 << (104 + 127)):
        tx = wrapper._calculateGrowthPortion(protocolGrowthPortion, poolGrowthPortion, increment, currentAccrued, currentPoolRatio)
        updatedAccrued, updatedPoolRatio = tx.return_value
        assert updatedAccrued == _updatedAccrued
        assert updatedPoolRatio == _updatedPoolRatio
    else:
        if _updatedAccrued >= (1 << 255):
            _updatedAccrued -= (1 << 256)
        with brownie.reverts('AccruedGrowthPortionOverflow: ' + str(_updatedAccrued)):
            tx = wrapper._calculateGrowthPortion(protocolGrowthPortion, poolGrowthPortion, increment, currentAccrued, currentPoolRatio)

@pytest.mark.parametrize('protocolGrowthPortion', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
@pytest.mark.parametrize('poolGrowthPortion', [0, oneX47 // 5, oneX47 // 4, oneX47 // 3, oneX47 // 2, oneX47])
def test_isGrowthPortion(wrapper, protocolGrowthPortion, poolGrowthPortion, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isGrowthPortion(protocolGrowthPortion, poolGrowthPortion)
    result = tx.return_value
    assert result == (protocolGrowthPortion > 0) or (poolGrowthPortion > 0)