# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, SwapWrapper
from sympy import Integer, floor, ceiling, exp
from Nofee import logTest, _accrued0_, _accrued1_, _integral0_, _integral1_, _amount0_, _amount1_, _poolRatio0_, _poolRatio1_, _growth_, _interval_, _originToOvershoot_, dataGeneration, toInt, twosComplementInt8, twosComplement, encodeCurve, amend, outgoing, incoming, getMaxIntegrals, encodeKernel
from X23_test import oneX23
from X47_test import oneX47

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

kk = 18
@pytest.mark.parametrize('n', range((kk * len(initializations['kernel'])) // 20, ((kk + 1) * len(initializations['kernel'])) // 20))
@pytest.mark.parametrize('logOffset', [-89, 0, 89])
@pytest.mark.parametrize('growth', [((1 << 127) - 1) // 5, (1 << 127) - (1 << 110)])
@pytest.mark.parametrize('sharesTotal', [1000, ((1 << 127) - 1) // 9])
@pytest.mark.parametrize('poolGrowthPortion', [oneX47 // 3])
@pytest.mark.parametrize('protocolGrowthPortion', [oneX47 // 5])
@pytest.mark.parametrize('accrued0', [((1 << 104) * (1 << 127)) // 3, ((1 << 104) * (1 << 127)) - ((1 << 17) * (1 << 127))])
@pytest.mark.parametrize('accrued1', [((1 << 104) * (1 << 127)) // 5, ((1 << 104) * (1 << 127)) - ((1 << 10) * (1 << 127))])
@pytest.mark.parametrize('poolRatio0', [(1 << 23) // 15])
@pytest.mark.parametrize('poolRatio1', [(1 << 23) // 77])
@pytest.mark.parametrize('amount0', [int256max // 9, - (int256max // 9)])
@pytest.mark.parametrize('amount1', [int256max // 13, - (int256max // 7)])
@pytest.mark.parametrize('amountSpecified', [int256max // 3])
@pytest.mark.parametrize('crossThreshold', [0])
def test_swapWithin(wrapper, n, logOffset, growth, sharesTotal, poolGrowthPortion, protocolGrowthPortion, accrued0, accrued1, poolRatio0, poolRatio1, amount0, amount1, amountSpecified, crossThreshold, request, worker_id):
    logTest(request, worker_id)
    
    poolId = twosComplementInt8(logOffset) << 180

    kernel = swaps['kernel'][n]
    curve = swaps['curve'][n]
    qLimit = swaps['target'][n]
    qLower = min(curve[0], curve[1])
    qUpper = max(curve[0], curve[1])
    qCurrent = curve[-1]

    outgoingMax, incomingMax = getMaxIntegrals(kernel)
    integral0 = outgoing(curve, kernel, qCurrent, qUpper)
    integral1 = outgoing(curve, kernel, qLower, qCurrent)

    zeroForOne = (qLimit <= qCurrent)

    sqrtOffset = floor((2 ** 127) * exp(Integer(logOffset) / 2))
    sqrtInverseOffset = floor((2 ** 127) / exp(Integer(logOffset) / 2))

    try:
        tx = wrapper._swapWithin(
            [
                poolId,
                growth,
                integral0,
                integral1,
                sharesTotal,
                outgoingMax,
                poolGrowthPortion,
                protocolGrowthPortion,
                accrued0,
                accrued1,
                poolRatio0,
                poolRatio1,
                twosComplement(amount0),
                twosComplement(amount1),
                twosComplement(amountSpecified),
                qLimit,
                crossThreshold,
                len(curve)
            ],
            encodeKernel(kernel),
            encodeCurve(curve)
        )
    except Exception as error:
        assert ('SafeInRangeAmountOverflow' in error.revert_msg) or \
            ('AccruedGrowthPortionOverflow' in error.revert_msg) or \
            ('GrowthOverflow' in error.revert_msg)
    else:
        data = tx.events['(unknown)'][0]['data']
        overshoot = toInt(tx.events['(unknown)'][0]['topic1'])
        integral0Amended = toInt(data[_integral0_ : _integral0_ + 27].hex())
        integral1Amended = toInt(data[_integral1_ : _integral1_ + 27].hex())
        accrued0Updated = toInt(data[_accrued0_ : _accrued0_ + 32].hex())
        accrued1Updated = toInt(data[_accrued1_ : _accrued1_ + 32].hex())
        amount0Updated = toInt(data[_amount0_ : _amount0_ + 32].hex())
        if amount0Updated >= (1 << 255):
            amount0Updated -= (1 << 256)
        amount1Updated = toInt(data[_amount1_ : _amount1_ + 32].hex())
        if amount1Updated >= (1 << 255):
            amount1Updated -= (1 << 256)
        poolRatio0Updated = toInt(data[_poolRatio0_ : _poolRatio0_ + 3].hex())
        poolRatio1Updated = toInt(data[_poolRatio1_ : _poolRatio1_ + 3].hex())
        growthAmended = toInt(data[_growth_ : _growth_ + 16].hex())
        interval = toInt(data[_interval_ : _originToOvershoot_ + 27].hex())

        if zeroForOne:
            _integral0Incremented = integral0 + incoming(curve, kernel, qLimit, qCurrent)
            _integral1Incremented = integral1 - outgoing(curve, kernel, qLimit, qCurrent)
        else:
            _integral0Incremented = integral0 - outgoing(curve, kernel, qCurrent, qLimit)
            _integral1Incremented = integral1 + incoming(curve, kernel, qCurrent, qLimit)
        _curveAmended = amend(amend(curve, overshoot), qLimit)
        _integral0Amended = outgoing(_curveAmended, kernel, qLimit, qUpper)
        _integral1Amended = outgoing(_curveAmended, kernel, qLower, qLimit)
        if _integral0Amended == 0:
            _growthFull = (growth * _integral1Incremented) //_integral1Amended
        elif _integral1Amended == 0:
            _growthFull = (growth * _integral0Incremented) //_integral0Amended
        else:
            _growthFull = min((growth * _integral0Incremented) //_integral0Amended, (growth * _integral1Incremented) //_integral1Amended)
        _growthAmended = growth + ceiling(Integer((_growthFull - growth) * (oneX47 - protocolGrowthPortion) * (oneX47 - poolGrowthPortion)) / (oneX47 * oneX47))
        _amount0Updated = amount0 + floor((Integer(sqrtInverseOffset) * _growthFull * sharesTotal * _integral0Amended) / (outgoingMax << 111)) - floor((Integer(sqrtInverseOffset) * growth * sharesTotal * integral0) / (outgoingMax << 111))
        _amount1Updated = amount1 + floor((Integer(sqrtOffset) * _growthFull * sharesTotal * _integral1Amended) / (outgoingMax << 111)) - floor((Integer(sqrtOffset) * growth * sharesTotal * integral1) / (outgoingMax << 111))
        _accrued0Updated = accrued0 + floor((Integer(sqrtInverseOffset) * (_growthFull - _growthAmended) * sharesTotal * _integral0Amended) / (outgoingMax << 111))
        _accrued1Updated = accrued1 + floor((Integer(sqrtOffset) * (_growthFull - _growthAmended) * sharesTotal * _integral1Amended) / (outgoingMax << 111))
        _poolRatio0Updated = floor((Integer(poolRatio0 * accrued0) + ((Integer(oneX23) * poolGrowthPortion * (oneX47 - protocolGrowthPortion) * (_growthFull - growth) * (_amount0Updated - amount0)) / (oneX47 * oneX47 * _growthFull))) / _accrued0Updated)
        _poolRatio1Updated = floor((Integer(poolRatio1 * accrued1) + ((Integer(oneX23) * poolGrowthPortion * (oneX47 - protocolGrowthPortion) * (_growthFull - growth) * (_amount1Updated - amount1)) / (oneX47 * oneX47 * _growthFull))) / _accrued1Updated)

        assert abs(growthAmended - _growthAmended) <= 1 << 5
        assert abs(integral0Amended - _integral0Amended) <= (1 << 32)
        assert abs(integral1Amended - _integral1Amended) <= (1 << 32)
        if _amount0Updated != amount0:
            assert abs(Integer(amount0Updated - _amount0Updated) / (_amount0Updated - amount0)) <= Integer(1) / (1 << 32)
        else:
            assert abs(amount0Updated - _amount0Updated) <= (1 << 96)
        if _amount1Updated != amount1:
            assert abs(Integer(amount1Updated - _amount1Updated) / (_amount1Updated - amount1)) <= Integer(1) / (1 << 32)
        else:
            assert abs(amount1Updated - _amount1Updated) <= (1 << 96)
        if _accrued0Updated != accrued0:
            assert abs(Integer(accrued0Updated - _accrued0Updated) / (_accrued0Updated - accrued0)) <= Integer(1) / (1 << 32)
        else:
            assert abs(accrued0Updated - _accrued0Updated) <= (1 << 96)
        if _accrued1Updated != accrued1:
            assert abs(Integer(accrued1Updated - _accrued1Updated) / (_accrued1Updated - accrued1)) <= Integer(1) / (1 << 32)
        else:
            assert abs(accrued1Updated - _accrued1Updated) <= (1 << 96)
        assert abs(poolRatio0Updated - _poolRatio0Updated) <= 10
        assert abs(poolRatio1Updated - _poolRatio1Updated) <= 10
        assert interval == 0

        assert _growthAmended <= (1 << 127)
        assert - (1 << 255) <= _amount0Updated < (1 << 255)
        assert - (1 << 255) <= _amount1Updated < (1 << 255)
        assert _accrued0Updated < (1 << 104) * (1 << 127)
        assert _accrued1Updated < (1 << 104) * (1 << 127)