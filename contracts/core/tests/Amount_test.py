# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from Nofee import logTest
from brownie import accounts, AmountWrapper
from sympy import Integer, ceiling


listOutgoingMax = [((1 << 216) - 1) // 5, ((1 << 216) - 1) // 3, ((1 << 216) - 1), ((1 << 100) - 1)]
listIntegral = [((1 << 216) - 1) // 5, ((1 << 216) - 1) // 3, ((1 << 216) - 1), ((1 << 100) - 1)]
listSqrtOffset = [((1 << 50) - 1), ((1 << 100) - 1), ((1 << 150) - 1), ((1 << 200) - 1)]
listAmountSpecified = [((1 << 50) - 1), ((1 << 100) - 1), ((1 << 150) - 1), ((1 << 200) - 1), (1 - (1 << 50)), (1 - (1 << 100)), (1 - (1 << 150)), (1 - (1 << 200))]
listGrowth = [((1 << 127) - 1) // 5, ((1 << 127) - 1) // 3, ((1 << 127) - 1)]
listTotalShares = [((1 << 127) - 1) // 5, ((1 << 127) - 1) // 3, ((1 << 127) - 1)]
listShares = [((1 << 127) - 1) // 5, ((1 << 127) - 1) // 3, ((1 << 127) - 1), (1 - (1 << 127)) // 5, (1 - (1 << 127)) // 3, (0 - (1 << 127))]
listGrowthMultiplier = [((1 << 256) - 1) // 5, ((1 << 256) - 1) // 3, ((1 << 256) - 1), ((1 << 256) - 1)]

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return AmountWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('outgoingMax', listOutgoingMax)
@pytest.mark.parametrize('sqrtOffset', listSqrtOffset)
@pytest.mark.parametrize('amountSpecified', listAmountSpecified + [0])
@pytest.mark.parametrize('growth', listGrowth)
@pytest.mark.parametrize('shares', listTotalShares + [0])
def test_calculateIntegralLimit(wrapper, outgoingMax, sqrtOffset, amountSpecified, growth, shares, request, worker_id):
    logTest(request, worker_id)

    sqrtInverseOffset = (2 ** 254) // sqrtOffset
    tx = wrapper.calculateIntegralLimitWrapper(outgoingMax, sqrtOffset, sqrtInverseOffset, amountSpecified, growth, shares)

    print(tx.gas_used)

    result0, result1 = tx.return_value
    if growth == 0 or shares == 0:
        assert result0 == 2 ** 216 - 1
        assert result1 == 2 ** 216 - 1
    else:
        if amountSpecified == 0:
            assert result0 == 0
            assert result1 == 0
        else: 
            if amountSpecified > 0:
                limit0 = (outgoingMax * sqrtInverseOffset * amountSpecified) // ((growth * shares) << 143)
                limit1 = (outgoingMax * sqrtOffset * amountSpecified) // ((growth * shares) << 143)
            else:
                limit0 = - ((outgoingMax * sqrtOffset * amountSpecified) // ((growth * shares) << 143))
                limit1 = - ((outgoingMax * sqrtInverseOffset * amountSpecified) // ((growth * shares) << 143))

            if limit0 > (2 ** 216) - 1:
                assert result0 == 2 ** 216 - 1
            else:
                assert result0 == limit0

            if limit1 > (2 ** 216) - 1:
                assert result1 == 2 ** 216 - 1
            else:
                assert result1 == limit1

@pytest.mark.parametrize('sqrtOffset', listSqrtOffset)
@pytest.mark.parametrize('growthMultiplier', listGrowthMultiplier)
@pytest.mark.parametrize('shares', listShares + [0])
@pytest.mark.parametrize('zeroOrOne', [False, True])
def test_outOfRangeAmount(wrapper, sqrtOffset, growthMultiplier, shares, zeroOrOne, request, worker_id):
    logTest(request, worker_id)
    
    sqrtInverseOffset = (2 ** 254) // sqrtOffset
    if zeroOrOne:
        expectedResult = ceiling(Integer(sqrtOffset * growthMultiplier * shares) / (2 ** 208))
    else:
        expectedResult = ceiling(Integer(sqrtInverseOffset * growthMultiplier * shares) / (2 ** 208))

    if (- 2 ** 255 <= expectedResult < 2 ** 255):
        tx = wrapper.safeOutOfRangeAmountWrapper(sqrtOffset, sqrtInverseOffset, growthMultiplier, shares, zeroOrOne)
        result = tx.return_value
        assert result == expectedResult
    else:
        with brownie.reverts():
            wrapper.safeOutOfRangeAmountWrapper(sqrtOffset, sqrtInverseOffset, growthMultiplier, shares, zeroOrOne)