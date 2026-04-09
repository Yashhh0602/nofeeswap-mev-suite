# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, CurveWrapper
from sympy import Integer, floor, exp
from eth_abi.packed import encode_packed
from Nofee import logTest, amend, dataGeneration, encodeCurve, thirtyTwoX59, minLogSpacing

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

maxCurveIndex = 0xFF

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

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return CurveWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('curveLength', [2, maxCurveIndex // 2, maxCurveIndex])
@pytest.mark.parametrize('curve', [128, 1000, 10000])
def test_member(wrapper, content, curveLength, curve, request, worker_id):
    logTest(request, worker_id)
    
    curveSequence = [
        content >> 192,
        (content >> 128) & 0xFFFFFFFFFFFFFFFF,
        (content >> 64) & 0xFFFFFFFFFFFFFFFF,
        content & 0xFFFFFFFFFFFFFFFF
    ] * curveLength
    curveSequence = curveSequence[0 : curveLength]
    curveArray = encodeCurve(curveSequence)

    tx = wrapper._member(curve, curveArray)
    result = tx.return_value
    assert result[0 : curveLength] == curveSequence

    tx = wrapper._boundaries(curve, curveArray)
    qLower, qUpper = tx.return_value
    assert qLower == min(curveSequence[0], curveSequence[1])
    assert qUpper == max(curveSequence[0], curveSequence[1])

@pytest.mark.parametrize('curve', [128, 1000, 10000])
@pytest.mark.parametrize('curveSequence', [
    [logPrice0, logPrice0 + minLogSpacing - 1],
    [logPrice0 + minLogSpacing - 1, logPrice0],
    [logPrice0, logPrice0 + minLogSpacing - 1, logPrice1],
    [logPrice0 + minLogSpacing - 1, logPrice0, logPrice1],
    [logPrice1, logPrice1 + minLogSpacing - 1],
    [logPrice1 + minLogSpacing - 1, logPrice1],
    [logPrice1, logPrice1 + minLogSpacing - 1, logPrice0],
    [logPrice1 + minLogSpacing - 1, logPrice1, logPrice0],
])
def test_validateLogSpacingIsTooSmall(wrapper, curve, curveSequence, request, worker_id):
    logTest(request, worker_id)
    
    curveArray = encodeCurve(curveSequence)
    with brownie.reverts('LogSpacingIsTooSmall: ' + str(minLogSpacing - 1)):
        tx = wrapper._validate(curve, curveArray)

@pytest.mark.parametrize('curve', [128, 1000, 10000])
@pytest.mark.parametrize('curveSequence', [
    [minLogSpacing, minLogSpacing + minLogSpacing],
    [minLogSpacing + minLogSpacing, minLogSpacing],
    [minLogSpacing, minLogSpacing + minLogSpacing, minLogSpacing + 1],
    [minLogSpacing + minLogSpacing, minLogSpacing, minLogSpacing + 1],
    [thirtyTwoX59 - minLogSpacing, thirtyTwoX59 - minLogSpacing - minLogSpacing],
    [thirtyTwoX59 - minLogSpacing - minLogSpacing, thirtyTwoX59 - minLogSpacing],
    [thirtyTwoX59 - minLogSpacing, thirtyTwoX59 - minLogSpacing - minLogSpacing, thirtyTwoX59 - minLogSpacing + 1],
    [thirtyTwoX59 - minLogSpacing - minLogSpacing, thirtyTwoX59 - minLogSpacing, thirtyTwoX59 - minLogSpacing + 1],
])
def test_validateBlankIntervalsShouldBeAvoided(wrapper, curve, curveSequence, request, worker_id):
    logTest(request, worker_id)
    
    curveArray = encodeCurve(curveSequence)
    qLower = min(curveSequence[0], curveSequence[1])
    qUpper = max(curveSequence[0], curveSequence[1])
    with brownie.reverts('BlankIntervalsShouldBeAvoided: ' + str(qLower) + ', ' + str(qUpper)):
        tx = wrapper._validate(curve, curveArray)

@pytest.mark.parametrize('curve', [128, 1000, 10000])
@pytest.mark.parametrize('curveSequence', [
    [logPrice2, logPrice2 + minLogSpacing, logPrice2],
    [logPrice2 + minLogSpacing, logPrice2, logPrice2],
    [logPrice2, logPrice2 + minLogSpacing, logPrice2 + minLogSpacing],
    [logPrice2 + minLogSpacing, logPrice2, logPrice2 + minLogSpacing],
])
def test_validateInvalidCurveArrangement(wrapper, curve, curveSequence, request, worker_id):
    logTest(request, worker_id)
    
    curveArray = encodeCurve(curveSequence)
    with brownie.reverts('InvalidCurveArrangement: ' + str(curveSequence[0]) + ', ' + str(curveSequence[1]) + ', ' + str(curveSequence[2])):
        tx = wrapper._validate(curve, curveArray)

@pytest.mark.parametrize('curve', [128, 1000, 10000])
@pytest.mark.parametrize('n', range(len(swaps['kernel'])))
def test_validate(wrapper, curve, n, request, worker_id):
    logTest(request, worker_id)
    
    curveSequence = swaps['curve'][n]
    curveArray = encodeCurve(curveSequence)
    tx = wrapper._validate(curve, curveArray)
    qLower, qUpper, qCurrent, qSpacing, sqrtSpacing, sqrtInverseSpacing, curveLength = tx.return_value

    assert qLower == min(curveSequence[0], curveSequence[1])
    assert qUpper == max(curveSequence[0], curveSequence[1])
    assert qCurrent == curveSequence[-1]
    assert qSpacing == qUpper - qLower
    assert sqrtSpacing == floor((2 ** 216) * exp(- Integer(qSpacing) / (2 ** 60)))
    assert sqrtInverseSpacing == floor((2 ** 216) * exp(- 16 + Integer(qSpacing) / (2 ** 60)))
    assert curveLength == len(curveSequence)

@pytest.mark.parametrize('qCurrent', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qOther', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('curve', [128, 1000, 10000])
def test_newCurve(wrapper, qCurrent, qOther, curve, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._newCurve(curve, qCurrent, qOther)
    _qCurrent, _qOther, curveLength = tx.return_value
    assert _qCurrent == qCurrent
    assert _qOther == qOther
    assert curveLength == 2

@pytest.mark.parametrize('curve', [160, 1000, 10000])
@pytest.mark.parametrize('n', range(len(swaps['kernel'])))
def test_amend(wrapper, curve, n, request, worker_id):
    logTest(request, worker_id)
    
    curveSequence = swaps['curve'][n]
    curveArray = encodeCurve(curveSequence)
    target = swaps['target'][n]
    tx = wrapper._amend(curve, len(curveSequence), target, curveArray)
    curveLengthAmended = tx.return_value

    curveSequenceAmended = amend(curveSequence, target)
    curveArrayAmended = encodeCurve(curveSequenceAmended)

    assert curveLengthAmended == len(curveSequenceAmended)
    assert tx.events['(unknown)']['data'].hex() == encode_packed(['uint256[]'], [curveArrayAmended]).hex()
