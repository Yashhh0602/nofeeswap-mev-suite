# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, SwapWrapper
from Nofee import logTest, dataGeneration

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

@pytest.mark.parametrize('zeroForOne', [False, True])
@pytest.mark.parametrize('amount0', [int256max // 9, int256max, - (int256max // 9), - int256max])
@pytest.mark.parametrize('amount1', [int256max // 9, int256max, - (int256max // 9), - int256max])
@pytest.mark.parametrize('amountSpecified', [int256max // 9, int256max, - (int256max // 9), - int256max])
@pytest.mark.parametrize('outgoingAmount', [int256max // 9, int256max // 5, int256max])
@pytest.mark.parametrize('incomingAmount', [int256max // 9, int256max // 5, int256max])
def test_updateAmounts(wrapper, zeroForOne, amount0, amount1, amountSpecified, outgoingAmount, incomingAmount, request, worker_id):
    logTest(request, worker_id)
    
    exactInput = amountSpecified > 0

    if zeroForOne:
        _amount0 = amount0 + incomingAmount
        _amount1 = amount1 - outgoingAmount
    else:
        _amount0 = amount0 - outgoingAmount
        _amount1 = amount1 + incomingAmount
    
    if exactInput:
        _amountSpecified = max(0, amountSpecified - incomingAmount)
    else:
        _amountSpecified = min(0, amountSpecified + outgoingAmount)
    
    if ((0 - (1 << 255)) <= _amount0) and (_amount0 <= ((1 << 255) - 1)) and ((0 - (1 << 255)) <= _amount1) and (_amount1 <= ((1 << 255) - 1)):
        tx = wrapper._updateAmounts(
            exactInput,
            zeroForOne,
            amount0,
            amount1,
            amountSpecified,
            outgoingAmount,
            incomingAmount
        )
        amount0Updated, amount1Updated, amountSpecifiedUpdated = tx.return_value
        assert amount0Updated == _amount0
        assert amount1Updated == _amount1
        assert amountSpecifiedUpdated == _amountSpecified
    else:
        with brownie.reverts():
            tx = wrapper._updateAmounts(
                exactInput,
                zeroForOne,
                amount0,
                amount1,
                amountSpecified,
                outgoingAmount,
                incomingAmount
            )