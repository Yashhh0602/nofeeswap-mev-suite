# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from Nofee import logTest
from brownie import accounts, IntegralWrapper
from sympy import Integer, Symbol, floor, integrate, exp

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return IntegralWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('integralValue', [2 ** 128 - 1, 2 ** 210])
@pytest.mark.parametrize('logPrice0', [1, 2 ** 63, 2 ** 64 - 1])
@pytest.mark.parametrize('logPrice1', [1, 2 ** 63, 2 ** 64 - 1])
@pytest.mark.parametrize('left', [False, True])
def test_shift(wrapper, integralValue, logPrice0, logPrice1, left, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.shift(integralValue, logPrice0, logPrice1, left)
    result = tx.return_value
    if left:
        sqrt0 = floor((2 ** 216) * exp(- Integer(logPrice0) / (2 ** 60)))
        sqrt1 = floor((2 ** 216) * exp(- Integer(logPrice1) / (2 ** 60)))
        assert result == floor(integralValue * sqrt0 * sqrt1 / ((2 ** 432) * exp(-16)))
    else:
        sqrt0 = floor((2 ** 216) * exp(+ Integer(logPrice0 - (2 ** 64)) / (2 ** 60)))
        sqrt1 = floor((2 ** 216) * exp(+ Integer(logPrice1 - (2 ** 64)) / (2 ** 60)))
        assert result == floor(integralValue * sqrt0 * sqrt1 / ((2 ** 432) * exp(-16)))

@pytest.mark.parametrize('integralValue', [1000, 2 ** 210])
def test_integral(wrapper, integralValue, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.integral(integralValue)
    assert tx.return_value == integralValue

@pytest.mark.parametrize('integralValue', [1000, 2 ** 210])
def test_setIntegral(wrapper, integralValue, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.setIntegral(integralValue)
    assert tx.return_value == integralValue

@pytest.mark.parametrize('integralValue', [1000, 2 ** 210])
@pytest.mark.parametrize('increment', [1, (2 ** 64) - 1])
def test_incrementIntegral(wrapper, integralValue, increment, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.incrementIntegral(integralValue, increment)
    assert tx.return_value == integralValue + increment

@pytest.mark.parametrize('integralValue', [1000, 2 ** 210])
@pytest.mark.parametrize('decrement', [1, 10])
def test_decrementIntegral(wrapper, integralValue, decrement, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.decrementIntegral(integralValue, decrement)
    assert tx.return_value == integralValue - decrement

@pytest.mark.parametrize('segment', [[1, 1000, 4, 10000], [1000, 1, 4, 10000]])
@pytest.mark.parametrize('target', [5, 100, 500])
def test_evaluate(wrapper, segment, target, request, worker_id):
    logTest(request, worker_id)
    
    b0, b1, c0, c1 = segment
    tx = wrapper.evaluate(b0, b1, c0, c1, target)
    b0 = Integer(b0 - (2 ** 63)) / (2 ** 59)
    b1 = Integer(b1 - (2 ** 63)) / (2 ** 59)
    c0 = Integer(c0) / (2 ** 15)
    c1 = Integer(c1) / (2 ** 15)
    target = Integer(target - (2 ** 63)) / (2 ** 59)
    assert tx.return_value == floor((2 ** 216) * (exp(-8) / 2) * (c0 + (c1 - c0) * (target - b0) / (b1 - b0)))

@pytest.mark.parametrize('data', [
    [1, 1000, 4, 10000, 5, 10],
    [1000, 1, 4, 10000, 10, 5],
    [1, 1000, 4, 10000, 100, 110],
    [1000, 1, 4, 10000, 110, 100],
    [1, 1000, 4, 10000, 500, 510],
    [1000, 1, 4, 10000, 510, 500],
    [1, 2, 1, 32768, 1, 2]
])
def test_outgoing(wrapper, data, request, worker_id):
    logTest(request, worker_id)
    
    b0, b1, c0, c1, fromLog, toLog = data
    tx = wrapper.outgoing(b0, b1, c0, c1, fromLog, toLog)
    print(tx.gas_used)
    b0 = Integer(b0) / (2 ** 59)
    b1 = Integer(b1) / (2 ** 59)
    c0 = Integer(c0) / (2 ** 15)
    c1 = Integer(c1) / (2 ** 15)
    fromLog = Integer(fromLog) / (2 ** 59)
    toLog = Integer(toLog) / (2 ** 59)

    fromSqrt = floor((2 ** 216) * exp(- fromLog / 2))
    fromSqrtInverse = floor((2 ** 216) * exp(-16 + fromLog / 2))
    toSqrt = floor((2 ** 216) * exp(- toLog / 2))
    toSqrtInverse = floor((2 ** 216) * exp(-16 + toLog / 2))

    h = Symbol('h')
    if toLog < fromLog:
        integral = floor(c0 * (fromSqrtInverse - toSqrtInverse) + ((fromSqrtInverse * (b0 - fromLog + 2) - toSqrtInverse * (b0 - toLog + 2)) * (c1 - c0)) / (b0 - b1))
        assert tx.return_value == integral
        assert abs(tx.return_value - floor((2 ** 216) * integrate(
            (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, min(fromLog, toLog), max(fromLog, toLog))))) <= 2 ** 64
    else:
        integral = floor(c0 * (fromSqrt - toSqrt) + ((fromSqrt * (fromLog - b0 + 2) - toSqrt * (toLog - b0 + 2)) * (c1 - c0)) / (b1 - b0))
        assert tx.return_value == integral
        assert abs(tx.return_value - floor((2 ** 216) * integrate(
            (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, min(fromLog, toLog), max(fromLog, toLog))))) <= 2 ** 64

@pytest.mark.parametrize('data', [
    [1, 1000, 4, 10000, 5, 10],
    [1000, 1, 4, 10000, 10, 5],
    [1, 1000, 4, 10000, 100, 110],
    [1000, 1, 4, 10000, 110, 100],
    [1, 1000, 4, 10000, 500, 510],
    [1000, 1, 4, 10000, 510, 500],
    [1, 2, 1, 32768, 1, 2]
])
def test_incoming(wrapper, data, request, worker_id):
    logTest(request, worker_id)
    
    b0, b1, c0, c1, fromLog, toLog = data
    tx = wrapper.incoming(b0, b1, c0, c1, fromLog, toLog)
    b0 = Integer(b0) / (2 ** 59)
    b1 = Integer(b1) / (2 ** 59)
    c0 = Integer(c0) / (2 ** 15)
    c1 = Integer(c1) / (2 ** 15)
    fromLog = Integer(fromLog) / (2 ** 59)
    toLog = Integer(toLog) / (2 ** 59)

    fromSqrt = floor((2 ** 216) * exp(- fromLog / 2))
    fromSqrtInverse = floor((2 ** 216) * exp(-16 + fromLog / 2))
    toSqrt = floor((2 ** 216) * exp(- toLog / 2))
    toSqrtInverse = floor((2 ** 216) * exp(-16 + toLog / 2))

    h = Symbol('h')
    if fromLog < toLog:
        integral = floor(c1 * (toSqrtInverse - fromSqrtInverse) - ((toSqrtInverse * (b1 - toLog + 2) - fromSqrtInverse * (b1 - fromLog + 2)) * (c1 - c0)) / (b1 - b0))
        assert tx.return_value == integral
        assert abs(tx.return_value - floor((2 ** 216) * integrate(
            (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, min(fromLog, toLog), max(fromLog, toLog)))) ) <= 2 ** 64
    else:
        integral = floor(c1 * (toSqrt - fromSqrt) - ((toSqrt * (toLog - b1 + 2) - fromSqrt * (fromLog - b1 + 2)) * (c1 - c0)) / (b0 - b1))
        assert tx.return_value == integral
        assert abs(tx.return_value - floor((2 ** 216) * integrate(
            (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, min(fromLog, toLog), max(fromLog, toLog)))) ) <= 2 ** 64