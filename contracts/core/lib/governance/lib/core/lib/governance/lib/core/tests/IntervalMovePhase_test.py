# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, thirtyTwoX59, dataGeneration

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

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
    return IntervalWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('index', [10, 200])
@pytest.mark.parametrize('left', [False, True])
@pytest.mark.parametrize('curveMember', [logPrice1, logPrice3, logPrice4])
@pytest.mark.parametrize('origin', [logPrice1, logPrice3, logPrice4])
@pytest.mark.parametrize('end', [logPrice1, logPrice3, logPrice4])
@pytest.mark.parametrize('kernelMember0', [logPrice1, logPrice2])
@pytest.mark.parametrize('kernelMember1', [logPrice1, logPrice3])
@pytest.mark.parametrize('memberHeight0', [height0, height2])
@pytest.mark.parametrize('memberHeight1', [height0, height2])
def test_movePhase(wrapper, index, left, curveMember, origin, end, kernelMember0, kernelMember1, memberHeight0, memberHeight1, request, worker_id):
    logTest(request, worker_id)
    
    indexCurve = index
    indexKernelTotal = index
    direction = left

    sqrtCurveMember = floor((2 ** 216) * exp(- Integer(curveMember) / (2 ** 60)))
    sqrtInverseCurveMember = floor((2 ** 216) * exp(- 16 + Integer(curveMember) / (2 ** 60)))

    sqrtOrigin = floor((2 ** 216) * exp(- Integer(origin) / (2 ** 60)))
    sqrtInverseOrigin = floor((2 ** 216) * exp(- 16 + Integer(origin) / (2 ** 60)))
    originContent0 = (0 << 240) + (origin << 176) + (sqrtOrigin >> 40)
    originContent1 = ((sqrtOrigin % (1 << 40)) << 216) + sqrtInverseOrigin

    sqrtEnd = floor((2 ** 216) * exp(- Integer(end) / (2 ** 60)))
    sqrtInverseEnd = floor((2 ** 216) * exp(- 16 + Integer(end) / (2 ** 60)))
    endContent0 = (0 << 240) + (end << 176) + (sqrtEnd >> 40)
    endContent1 = ((sqrtEnd % (1 << 40)) << 216) + sqrtInverseEnd

    sqrtKernel0 = floor((2 ** 216) * exp(- Integer(kernelMember0) / (2 ** 60)))
    sqrtInverseKernel0 = floor((2 ** 216) * exp(- 16 + Integer(kernelMember0) / (2 ** 60)))
    kernel0Content0 = (memberHeight0 << 240) + (kernelMember0 << 176) + (sqrtKernel0 >> 40)
    kernel0Content1 = ((sqrtKernel0 % (1 << 40)) << 216) + sqrtInverseKernel0

    sqrtKernel1 = floor((2 ** 216) * exp(- Integer(kernelMember1) / (2 ** 60)))
    sqrtInverseKernel1 = floor((2 ** 216) * exp(- 16 + Integer(kernelMember1) / (2 ** 60)))
    kernel1Content0 = (memberHeight1 << 240) + (kernelMember1 << 176) + (sqrtKernel1 >> 40)
    kernel1Content1 = ((sqrtKernel1 % (1 << 40)) << 216) + sqrtInverseKernel1

    tx = wrapper._movePhase(
        indexCurve,
        indexKernelTotal,
        direction,
        curveMember,
        [
            originContent0,
            originContent1,
            endContent0,
            endContent1,
            kernel0Content0,
            kernel0Content1,
            kernel1Content0,
            kernel1Content1,
        ]
    )

    _indexCurve, _direction, output = tx.return_value

    _beginContent0 = output[0]
    _beginContent1 = output[1]
    beginLogPrice = (_beginContent0 >> 176) % (1 << 64)
    beginSqrtPrice = ((_beginContent0 % (1 << 176)) << 40) + (_beginContent1 >> 216)
    beginSqrtInversePrice = _beginContent1 % (1 << 216)

    _originContent0 = output[2]
    _originContent1 = output[3]
    originLogPrice = (_originContent0 >> 176) % (1 << 64)
    originSqrtPrice = ((_originContent0 % (1 << 176)) << 40) + (_originContent1 >> 216)
    originSqrtInversePrice = _originContent1 % (1 << 216)

    _endContent0 = output[4]
    _endContent1 = output[5]
    endLogPrice = (_endContent0 >> 176) % (1 << 64)
    endSqrtPrice = ((_endContent0 % (1 << 176)) << 40) + (_endContent1 >> 216)
    endSqrtInversePrice = _endContent1 % (1 << 216)

    _total0Content0 = output[6]
    _total0Content1 = output[7]
    total0Height = _total0Content0 >> 240
    total0LogPrice = (_total0Content0 >> 176) % (1 << 64)
    total0SqrtPrice = ((_total0Content0 % (1 << 176)) << 40) + (_total0Content1 >> 216)
    total0SqrtInversePrice = _total0Content1 % (1 << 216)

    _total1Content0 = output[8]
    _total1Content1 = output[9]
    total1Height = _total1Content0 >> 240
    total1LogPrice = (_total1Content0 >> 176) % (1 << 64)
    total1SqrtPrice = ((_total1Content0 % (1 << 176)) << 40) + (_total1Content1 >> 216)
    total1SqrtInversePrice = _total1Content1 % (1 << 216)

    assert beginLogPrice == origin
    assert abs(beginSqrtPrice - sqrtOrigin) <= 100
    assert abs(beginSqrtInversePrice - sqrtInverseOrigin) <= 100

    assert originLogPrice == end
    assert abs(originSqrtPrice - sqrtEnd) <= 100
    assert abs(originSqrtInversePrice - sqrtInverseEnd) <= 100

    assert endLogPrice == curveMember
    assert abs(endSqrtPrice - sqrtCurveMember) <= 100
    assert abs(endSqrtInversePrice - sqrtInverseCurveMember) <= 100
    
    assert _direction == (False if direction else True)
    assert _indexCurve == indexCurve - 1

    if (_direction and (originLogPrice > kernelMember0)) or (not(_direction) and (originLogPrice + kernelMember0 < thirtyTwoX59)):
        assert total0Height == memberHeight0
        assert total0LogPrice == originLogPrice - kernelMember0 if _direction else originLogPrice + kernelMember0
        assert abs(total0SqrtPrice - floor((2 ** 216) * exp(- Integer(total0LogPrice) / (2 ** 60)))) <= (1 << 32)
        assert abs(total0SqrtInversePrice - floor((2 ** 216) * exp(- 16 + Integer(total0LogPrice) / (2 ** 60)))) <= (1 << 32)

    if (_direction and (originLogPrice > kernelMember1)) or (not(_direction) and (originLogPrice + kernelMember1 < thirtyTwoX59)):
        assert total1Height == memberHeight1
        assert total1LogPrice == originLogPrice - kernelMember1 if _direction else originLogPrice + kernelMember1
        assert abs(total1SqrtPrice - floor((2 ** 216) * exp(- Integer(total1LogPrice) / (2 ** 60)))) <= (1 << 32)
        assert abs(total1SqrtInversePrice - floor((2 ** 216) * exp(- 16 + Integer(total1LogPrice) / (2 ** 60)))) <= (1 << 32)