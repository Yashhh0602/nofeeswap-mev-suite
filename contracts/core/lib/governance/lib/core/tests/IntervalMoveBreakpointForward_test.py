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

@pytest.mark.parametrize('forward1Height', [height0, height2, height4])
@pytest.mark.parametrize('forward1Log', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('targetLog', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('memberHeight', [height0, height2, height4])
@pytest.mark.parametrize('memberLog', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('index', [10, 200])
@pytest.mark.parametrize('left', [False, True])
def test_moveBreakpointForward(wrapper, forward1Height, forward1Log, targetLog, memberHeight, memberLog, index, left, request, worker_id):
    logTest(request, worker_id)
    
    sqrtForward1 = floor((2 ** 216) * exp(- Integer(forward1Log) / (2 ** 60)))
    sqrtInverseForward1 = floor((2 ** 216) * exp(- 16 + Integer(forward1Log) / (2 ** 60)))
    forward1Content0 = (forward1Height << 240) + (forward1Log << 176) + (sqrtForward1 >> 40)
    forward1Content1 = ((sqrtForward1 % (1 << 40)) << 216) + sqrtInverseForward1

    sqrtTarget = floor((2 ** 216) * exp(- Integer(targetLog) / (2 ** 60)))
    sqrtInverseTarget = floor((2 ** 216) * exp(- 16 + Integer(targetLog) / (2 ** 60)))
    targetContent0 = (0 << 240) + (targetLog << 176) + (sqrtTarget >> 40)
    targetContent1 = ((sqrtTarget % (1 << 40)) << 216) + sqrtInverseTarget

    sqrtMember = floor((2 ** 216) * exp(- Integer(memberLog) / (2 ** 60)))
    sqrtInverseMember = floor((2 ** 216) * exp(- 16 + Integer(memberLog) / (2 ** 60)))
    memberContent0 = (memberHeight << 240) + (memberLog << 176) + (sqrtMember >> 40)
    memberContent1 = ((sqrtMember % (1 << 40)) << 216) + sqrtInverseMember

    if (left and (targetLog > memberLog)) or (not(left) and (targetLog + memberLog < thirtyTwoX59)):
        tx = wrapper._moveBreakpointForward(
            forward1Content0,
            forward1Content1,
            targetContent0,
            targetContent1,
            memberContent0,
            memberContent1,
            index,
            left
        )
        
        (
            forward0Content0,
            forward0Content1,
            forward1Content0,
            forward1Content1,
            index
        ) = tx.return_value

        height0 = forward0Content0 >> 240
        logPrice0 = (forward0Content0 >> 176) % (1 << 64)
        sqrtPrice0 = ((forward0Content0 % (1 << 176)) << 40) + (forward0Content1 >> 216)
        sqrtInversePrice0 = forward0Content1 % (1 << 216)

        height1 = forward1Content0 >> 240
        logPrice1 = (forward1Content0 >> 176) % (1 << 64)
        sqrtPrice1 = ((forward1Content0 % (1 << 176)) << 40) + (forward1Content1 >> 216)
        sqrtInversePrice1 = forward1Content1 % (1 << 216)

        heightResultant = memberHeight
        logResultant = targetLog - memberLog if left else targetLog + memberLog
        sqrtResultant = floor((2 ** 216) * exp(- Integer(logResultant) / (2 ** 60)))
        sqrtInverseResultant = floor((2 ** 216) * exp(- 16 + Integer(logResultant) / (2 ** 60)))

        assert height0 == forward1Height
        assert logPrice0 == forward1Log
        assert sqrtPrice0 == sqrtForward1
        assert sqrtInversePrice0 == sqrtInverseForward1

        assert height1 == heightResultant
        assert logPrice1 == logResultant
        assert abs(sqrtPrice1 - sqrtResultant) < (1 << 32)
        assert abs(sqrtInversePrice1 - sqrtInverseResultant) < (1 << 32)