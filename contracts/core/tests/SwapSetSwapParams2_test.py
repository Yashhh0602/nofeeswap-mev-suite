# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, SwapWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, X216, _logPriceLimitOffsetted_, _zeroForOne_, _exactInput_, _back_, _next_, _integralLimit_, _integralLimitInterval_, thirtyTwoX59, dataGeneration, toInt, twosComplementInt8

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

@pytest.mark.parametrize('zeroForOne_', [2])
@pytest.mark.parametrize('logOffset', [-89, 0, 89])
@pytest.mark.parametrize('q0', [logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('q1', [logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qCurrent', [logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qLimit', [logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('amountSpecified', [int256max // 9, - (int256max // 9)])
@pytest.mark.parametrize('outgoingMax', [X216 // 9])
@pytest.mark.parametrize('incomingMax', [X216 // 5])
@pytest.mark.parametrize('growth', [((1 << 127) - 1) // 5, ((1 << 127) - 1)])
@pytest.mark.parametrize('sharesTotal', [((1 << 127) - 1) // 5, ((1 << 127) - 1)])
def test_setSwapParams(wrapper, zeroForOne_, logOffset, q0, q1, qCurrent, qLimit, amountSpecified, outgoingMax, incomingMax, growth, sharesTotal, request, worker_id):
    logTest(request, worker_id)
    
    if q0 != q1:
        _sqrtOffset = floor((2 ** 127) * exp(Integer(logOffset) / 2))
        _sqrtInverseOffset = floor((2 ** 127) / exp(Integer(logOffset) / 2))

        qLower = min(q0, q1)
        qUpper = max(q0, q1)
        qSpacing = qUpper - qLower

        qLeast = qUpper % qSpacing
        while qLeast <= qSpacing:
            qLeast += qSpacing

        qMost = thirtyTwoX59 - ((thirtyTwoX59 - qUpper) % qSpacing)
        while thirtyTwoX59 - qSpacing <= qMost:
            qMost -= qSpacing

        _qLimitOffsetted = min(max(qLeast, qLimit), qMost)
        _zeroForOne = _qLimitOffsetted <= qCurrent
        _exactInput = (amountSpecified >= 0)

        if _zeroForOne:
            _back = qUpper
            _next = qLower
        else:
            _back = qLower
            _next = qUpper

        if (_zeroForOne != _exactInput):
            _integralLimit = floor((Integer(outgoingMax << 111) * abs(amountSpecified) * _sqrtInverseOffset) / (Integer(sharesTotal) * growth * (1 << 127) * (1 << 127)))
        else:
            _integralLimit = floor((Integer(outgoingMax << 111) * abs(amountSpecified) * _sqrtOffset) / (Integer(sharesTotal) * growth * (1 << 127) * (1 << 127)))

        if _exactInput:
            if _zeroForOne:
                _integralLimitInterval = floor(incomingMax * exp(+ 8 - Integer(_next) / (2 ** 60)))
            else:
                _integralLimitInterval = floor(incomingMax * exp(- 8 + Integer(_next) / (2 ** 60)))
        else:
            if _zeroForOne:
                _integralLimitInterval = floor(outgoingMax * exp(- 8 + Integer(_back) / (2 ** 60)))
            else:
                _integralLimitInterval = floor(outgoingMax * exp(+ 8 - Integer(_back) / (2 ** 60)))

        if (zeroForOne_ <= 1) and ((zeroForOne_ > 0) != _zeroForOne):
            with brownie.reverts('InvalidDirection: ' + str(qCurrent) + ', ' + str(_qLimitOffsetted)):
                tx = wrapper._setSwapParams(
                    zeroForOne_,
                    twosComplementInt8(logOffset) << 180,
                    (q0 << 192) + (q1 << 128) + (qCurrent << 64),
                    qLimit - (thirtyTwoX59 // 2) + ((1 << 59) * logOffset),
                    amountSpecified,
                    outgoingMax,
                    incomingMax,
                    growth,
                    sharesTotal
                )
        else:
            tx = wrapper._setSwapParams(
                zeroForOne_,
                twosComplementInt8(logOffset) << 180,
                (q0 << 192) + (q1 << 128) + (qCurrent << 64),
                qLimit - (thirtyTwoX59 // 2) + ((1 << 59) * logOffset),
                amountSpecified,
                outgoingMax,
                incomingMax,
                growth,
                sharesTotal
            )

            data = tx.events['(unknown)'][0]['data']

            qLimitOffsetted = toInt(data[_logPriceLimitOffsetted_ : _logPriceLimitOffsetted_ + 8].hex())
            zeroForOne = toInt(data[_zeroForOne_ : _zeroForOne_ + 1].hex()) > 0
            exactInput = toInt(data[_exactInput_ : _exactInput_ + 1].hex()) > 0
            
            back = toInt(data[_back_ : _back_ + 8].hex())
            backSqrt = toInt(data[_back_ + 8 : _back_ + 35].hex())
            backSqrtInverse = toInt(data[_back_ + 35 : _back_ + 62].hex())

            next = toInt(data[_next_ : _next_ + 8].hex())
            nextSqrt = toInt(data[_next_ + 8 : _next_ + 35].hex())
            nextSqrtInverse = toInt(data[_next_ + 35 : _next_ + 62].hex())

            integralLimit = toInt(data[_integralLimit_ : _integralLimit_ + 27].hex())
            integralLimitInterval = toInt(data[_integralLimitInterval_ : _integralLimitInterval_ + 27].hex())

            assert qLimitOffsetted == _qLimitOffsetted
            assert zeroForOne == _zeroForOne
            assert exactInput == _exactInput

            assert back == _back
            assert abs(backSqrt - floor((2 ** 216) * exp(- Integer(back) / (2 ** 60)))) <= 1 << 32
            assert abs(backSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(back) / (2 ** 60)))) <= 1 << 32

            assert next == _next
            assert abs(nextSqrt - floor((2 ** 216) * exp(- Integer(next) / (2 ** 60)))) <= 1 << 32
            assert abs(nextSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(next) / (2 ** 60)))) <= 1 << 32

            if _integralLimit < X216:
                assert abs(integralLimit - _integralLimit) <= 1 << 32
            
            if _integralLimitInterval < X216:
                assert abs(integralLimitInterval - _integralLimitInterval) <= 1 << 32