# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from Nofee import logTest
from brownie import accounts, AmountWrapper
from sympy import Integer, floor, ceiling

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

@pytest.mark.parametrize('sqrtOffset', listSqrtOffset)
@pytest.mark.parametrize('integral', listIntegral + [0])
@pytest.mark.parametrize('growth', listGrowth)
@pytest.mark.parametrize('shares', listShares + [0])
@pytest.mark.parametrize('outgoingMax', listOutgoingMax)
@pytest.mark.parametrize('zeroOrOne', [False])
@pytest.mark.parametrize('roundUp', [False])
def test_mulDivByOutgoingMax(wrapper, sqrtOffset, integral, growth, shares, outgoingMax, zeroOrOne, roundUp, request, worker_id):
    logTest(request, worker_id)
    
    sqrtInverseOffset = (2 ** 254) // sqrtOffset
    if zeroOrOne:
        numerator = Integer(sqrtOffset * integral * growth * shares)
    else:
        numerator = Integer(sqrtInverseOffset * integral * growth * shares)

    if roundUp:
        expectedResult = ceiling(numerator / (outgoingMax * (2 ** 111)))
    else:
        expectedResult = floor(numerator / (outgoingMax * (2 ** 111)))

    outgoingMaxModularInverse = outgoingMax
    while outgoingMaxModularInverse % 2 != 1:
        outgoingMaxModularInverse = outgoingMaxModularInverse // 2
    outgoingMaxModularInverse = pow(outgoingMaxModularInverse, -1, 2 ** 256)
    
    if (- 2 ** 255 < expectedResult < 2 ** 255):
        tx = wrapper.inRangeAmountWrapper(sqrtOffset, sqrtInverseOffset, integral, growth, shares, outgoingMax, outgoingMaxModularInverse, zeroOrOne, roundUp)
        result, overflow = tx.return_value
        assert result == expectedResult
        assert overflow == False
        tx = wrapper.safeInRangeAmountWrapper(sqrtOffset, sqrtInverseOffset, integral, growth, shares, outgoingMax, outgoingMaxModularInverse, zeroOrOne, roundUp)
        assert result == expectedResult
    else:
        tx = wrapper.inRangeAmountWrapper(sqrtOffset, sqrtInverseOffset, integral, growth, shares, outgoingMax, outgoingMaxModularInverse, zeroOrOne, roundUp)
        result, overflow = tx.return_value
        assert overflow == True
        with brownie.reverts():
            wrapper.safeInRangeAmountWrapper(sqrtOffset, sqrtInverseOffset, integral, growth, shares, outgoingMax, outgoingMaxModularInverse, zeroOrOne, roundUp)