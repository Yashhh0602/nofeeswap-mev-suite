# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, SwapWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, X216, _curveLength_, _integral0_, _integral1_, _backGrowthMultiplier_, _nextGrowthMultiplier_, _sharesTotal_, _growth_, _back_, _next_, dataGeneration, toInt, twosComplementInt8
from X111_test import oneX111
from X208_test import oneX208

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

@pytest.mark.parametrize('logOffset', [-89, 0, 89])
@pytest.mark.parametrize('outgoingMax', [X216 // (1 << 80)])
@pytest.mark.parametrize('incomingMax', [X216 // (1 << 70)])
@pytest.mark.parametrize('back', [midpoint - spacing, midpoint, midpoint + spacing])
@pytest.mark.parametrize('next', [midpoint - spacing, midpoint, midpoint + spacing])
@pytest.mark.parametrize('growth', [((1 << 127) - 1) // 5, (1 << 127) - (1 << 110)])
@pytest.mark.parametrize('sharesTotal', [(1 << 127) - 1])
@pytest.mark.parametrize('amountSpecified', [int256max // 3])
@pytest.mark.parametrize('backGrowthMultiplier', [oneX208 // 55, oneX208 // 37])
@pytest.mark.parametrize('nextGrowthMultiplier', [oneX208 // 17, oneX208 // 11])
@pytest.mark.parametrize('furtherGrowthMultiplier', [oneX208 // 53, oneX208 // 31])
@pytest.mark.parametrize('sharesDelta', [1000, ((1 << 127) - 1) // 9])
def test_transition(wrapper, logOffset, outgoingMax, incomingMax, back, next, growth, sharesTotal, amountSpecified, backGrowthMultiplier, nextGrowthMultiplier, furtherGrowthMultiplier, sharesDelta, request, worker_id):
    logTest(request, worker_id)
    
    if back != next:
        poolId = twosComplementInt8(logOffset) << 180

        if outgoingMax > incomingMax:
            outgoingMax, incomingMax = incomingMax, outgoingMax

        if furtherGrowthMultiplier == 0:
            furtherGrowthMultiplierZero = True
            furtherGrowthMultiplier = floor((oneX208 * exp(- Integer(next) / (2 ** 60))) / (1 - exp(- Integer(min(next, back) - max(next, back)) / (2 ** 60))))
        else:
            furtherGrowthMultiplierZero = False

        zeroForOne = (next <= back)

        if zeroForOne:
            _integral0Updated = 0
            _integral1Updated = floor(exp(- 8 + Integer(next) / (2 ** 60)) * outgoingMax)
            _backUpdated = next
            _nextUpdated = next + next - back
            _backGrowthMultiplierUpdated = backGrowthMultiplier + floor(exp(+ 8 - Integer(next) / (2 ** 60)) * growth * (2 ** (208 - 111)))
            _nextGrowthMultiplierUpdated = furtherGrowthMultiplier
            _growthUpdated = max(oneX111, floor(exp(+ 8 - Integer(next) / (2 ** 60)) * (nextGrowthMultiplier - furtherGrowthMultiplier) / (2 ** (208 - 111))))
            _sharesTotalUpdated = sharesTotal - sharesDelta
        else:
            _integral0Updated = floor(exp(+ 8 - Integer(next) / (2 ** 60)) * outgoingMax)
            _integral1Updated = 0
            _backUpdated = next
            _nextUpdated = next + next - back
            _backGrowthMultiplierUpdated = backGrowthMultiplier + floor(exp(- 8 + Integer(next) / (2 ** 60)) * growth * (2 ** (208 - 111)))
            _nextGrowthMultiplierUpdated = furtherGrowthMultiplier
            _growthUpdated = max(oneX111, floor(exp(- 8 + Integer(next) / (2 ** 60)) * (nextGrowthMultiplier - furtherGrowthMultiplier) / (2 ** (208 - 111))))
            _sharesTotalUpdated = sharesTotal + sharesDelta

        tx = wrapper._transition(
            [
                poolId,
                outgoingMax,
                incomingMax,
                back,
                next,
                growth,
                sharesTotal,
                amountSpecified,
                backGrowthMultiplier,
                nextGrowthMultiplier,
                0 if furtherGrowthMultiplierZero else furtherGrowthMultiplier,
                sharesDelta
            ]
        )

        member0 = toInt(tx.events['(unknown)'][0]['topic1'])
        member1 = toInt(tx.events['(unknown)'][0]['topic2'])
        data = tx.events['(unknown)'][0]['data']
        integral0Updated = toInt(data[_integral0_ : _integral0_ + 27].hex())
        integral1Updated = toInt(data[_integral1_ : _integral1_ + 27].hex())
        backUpdated = toInt(data[_back_ : _back_ + 8].hex())
        nextUpdated = toInt(data[_next_ : _next_ + 8].hex())
        backGrowthMultiplierUpdated = toInt(data[_backGrowthMultiplier_ : _backGrowthMultiplier_ + 32].hex())
        nextGrowthMultiplierUpdated = toInt(data[_nextGrowthMultiplier_ : _nextGrowthMultiplier_ + 32].hex())
        growthUpdated = toInt(data[_growth_ : _growth_ + 16].hex())
        sharesTotalUpdated = toInt(data[_sharesTotal_ : _sharesTotal_ + 16].hex())
        curveLengthUpdated = toInt(data[_curveLength_ : _curveLength_ + 2].hex())

        assert abs(integral0Updated - _integral0Updated) <= 1 << 32
        assert abs(integral1Updated - _integral1Updated) <= 1 << 32
        assert backUpdated == _backUpdated
        assert nextUpdated == _nextUpdated
        assert abs(backGrowthMultiplierUpdated - _backGrowthMultiplierUpdated) <= 1 << 32
        assert abs(nextGrowthMultiplierUpdated - _nextGrowthMultiplierUpdated) <= 1 << 32
        assert growthUpdated == _growthUpdated
        assert sharesTotalUpdated == _sharesTotalUpdated
        assert curveLengthUpdated == 2
        assert member0 == nextUpdated
        assert member1 == backUpdated