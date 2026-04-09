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

@pytest.mark.parametrize('total1Height', [height0, height2, height4])
@pytest.mark.parametrize('total1Log', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('originLog', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('memberHeight', [height0, height2, height4])
@pytest.mark.parametrize('memberLog', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('index', [10, 200])
@pytest.mark.parametrize('left', [False, True])
def test_moveBreakpointTotal(wrapper, total1Height, total1Log, originLog, memberHeight, memberLog, index, left, request, worker_id):
    logTest(request, worker_id)
    
    sqrtTotal1 = floor((2 ** 216) * exp(- Integer(total1Log) / (2 ** 60)))
    sqrtInverseTotal1 = floor((2 ** 216) * exp(- 16 + Integer(total1Log) / (2 ** 60)))
    total1Content0 = (total1Height << 240) + (total1Log << 176) + (sqrtTotal1 >> 40)
    total1Content1 = ((sqrtTotal1 % (1 << 40)) << 216) + sqrtInverseTotal1

    sqrtOrigin = floor((2 ** 216) * exp(- Integer(originLog) / (2 ** 60)))
    sqrtInverseOrigin = floor((2 ** 216) * exp(- 16 + Integer(originLog) / (2 ** 60)))
    originContent0 = (0 << 240) + (originLog << 176) + (sqrtOrigin >> 40)
    originContent1 = ((sqrtOrigin % (1 << 40)) << 216) + sqrtInverseOrigin

    sqrtMember = floor((2 ** 216) * exp(- Integer(memberLog) / (2 ** 60)))
    sqrtInverseMember = floor((2 ** 216) * exp(- 16 + Integer(memberLog) / (2 ** 60)))
    memberContent0 = (memberHeight << 240) + (memberLog << 176) + (sqrtMember >> 40)
    memberContent1 = ((sqrtMember % (1 << 40)) << 216) + sqrtInverseMember

    if (left and (originLog > memberLog)) or (not(left) and (originLog + memberLog < thirtyTwoX59)):
        tx = wrapper._moveBreakpointTotal(
            total1Content0,
            total1Content1,
            originContent0,
            originContent1,
            memberContent0,
            memberContent1,
            index,
            left
        )
        
        (
            total0Content0,
            total0Content1,
            total1Content0,
            total1Content1,
            index
        ) = tx.return_value

        height0 = total0Content0 >> 240
        logPrice0 = (total0Content0 >> 176) % (1 << 64)
        sqrtPrice0 = ((total0Content0 % (1 << 176)) << 40) + (total0Content1 >> 216)
        sqrtInversePrice0 = total0Content1 % (1 << 216)

        height1 = total1Content0 >> 240
        logPrice1 = (total1Content0 >> 176) % (1 << 64)
        sqrtPrice1 = ((total1Content0 % (1 << 176)) << 40) + (total1Content1 >> 216)
        sqrtInversePrice1 = total1Content1 % (1 << 216)

        heightResultant = memberHeight
        logResultant = originLog - memberLog if left else originLog + memberLog
        sqrtResultant = floor((2 ** 216) * exp(- Integer(logResultant) / (2 ** 60)))
        sqrtInverseResultant = floor((2 ** 216) * exp(- 16 + Integer(logResultant) / (2 ** 60)))

        assert height0 == total1Height
        assert logPrice0 == total1Log
        assert sqrtPrice0 == sqrtTotal1
        assert sqrtInversePrice0 == sqrtInverseTotal1

        assert height1 == heightResultant
        assert logPrice1 == logResultant
        assert abs(sqrtPrice1 - sqrtResultant) < (1 << 32)
        assert abs(sqrtInversePrice1 - sqrtInverseResultant) < (1 << 32)