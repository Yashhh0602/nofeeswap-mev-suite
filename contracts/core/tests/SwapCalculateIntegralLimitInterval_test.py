# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, SwapWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, X216, dataGeneration

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

int256max = (1 << 255) - 1

maxCurveIndex = 0xFFF

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF

height0 = 0x0000
height1 = 0x0111
height2 = 0x1F0F
height3 = 0x3FFF
height4 = 0x8000

midpoint = 0x8000000000000000
spacing = 0x0800000000000000

points = [
    (0 * spacing) // 10,
    (1 * spacing) // 10,
    (2 * spacing) // 10,
    (3 * spacing) // 10,
    (4 * spacing) // 10,
    (5 * spacing) // 10,
    (6 * spacing) // 10,
]

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return SwapWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('exactInput', [False, True])
@pytest.mark.parametrize('zeroForOne', [False, True])
@pytest.mark.parametrize('back', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('next', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('outgoingMax', [X216 // 9, X216 // 5, X216 - 1])
@pytest.mark.parametrize('incomingMax', [X216 // 9, X216 // 5, X216 - 1])
def test_calculateIntegralLimitInterval(wrapper, exactInput, zeroForOne, back, next, outgoingMax, incomingMax, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._calculateIntegralLimitInterval(
        exactInput,
        zeroForOne,
        back,
        next,
        outgoingMax,
        incomingMax
    )

    integralLimitInterval = tx.return_value

    if exactInput:
        if zeroForOne:
            _integralLimitInterval = floor(incomingMax * exp(+ 8 - Integer(next) / (2 ** 60)))
        else:
            _integralLimitInterval = floor(incomingMax * exp(- 8 + Integer(next) / (2 ** 60)))
    else:
        if zeroForOne:
            _integralLimitInterval = floor(outgoingMax * exp(- 8 + Integer(back) / (2 ** 60)))
        else:
            _integralLimitInterval = floor(outgoingMax * exp(+ 8 - Integer(back) / (2 ** 60)))

    if _integralLimitInterval < X216:
        assert abs(integralLimitInterval - _integralLimitInterval) <= (1 << 32)