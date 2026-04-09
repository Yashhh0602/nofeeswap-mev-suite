# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from Nofee import logTest
from brownie import accounts, FullMathWrapper
from sympy import Integer, floor, ceiling

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return FullMathWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('a0', [value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('a1', [value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('b0', [value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('b1', [value2 // 7, value2 // 5, value2 // 3, value2])
def test_add512(wrapper, a0, a1, b0, b1, request, worker_id):
    logTest(request, worker_id)
    
    result = ((a1 << 256) + a0) + ((b1 << 256) + b0)
    tx = wrapper.add512(a0, a1, b0, b1)
    r0, r1 = tx.return_value
    if result < (1 << 512):
        assert result == ((r1 << 256) + r0)

@pytest.mark.parametrize('a0', [value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('a1', [value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('b0', [value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('b1', [value2 // 7, value2 // 5, value2 // 3, value2])
def test_sub512(wrapper, a0, a1, b0, b1, request, worker_id):
    logTest(request, worker_id)
    
    result = ((a1 << 256) + a0) - ((b1 << 256) + b0)
    tx = wrapper.sub512(a0, a1, b0, b1)
    r0, r1 = tx.return_value
    if result >= 0:
        assert result == ((r1 << 256) + r0)

@pytest.mark.parametrize('a', [value2 // 7, value2 // 5, value2 // 3, value2, value4 // 7, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('b', [value2 // 7, value2 // 5, value2 // 3, value2, value4 // 7, value4 // 5, value4 // 3, value4])
def test_mul512(wrapper, a, b, request, worker_id):
    logTest(request, worker_id)
    
    result = a * b
    tx = wrapper.mul512(a, b)
    r0, r1 = tx.return_value
    if result >= 0:
        assert result == ((r1 << 256) + r0)

@pytest.mark.parametrize('value', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('numerator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('denominator', [value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
def test_cheapMulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if value * numerator < denominator * (denominator - 1):
        tx = wrapper.cheapMulDiv(value, numerator, denominator)
        result = tx.return_value
        assert result == (value * numerator) // denominator

@pytest.mark.parametrize('value', [value1, value2, value3, value4])
def test_modularInverse(wrapper, value, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.modularInverse(value)
    result = tx.return_value
    assert (value * result) % (1 << 256) == 1

@pytest.mark.parametrize('a', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('b', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('c', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('d', [value0, value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('roundUp', [False, True])
def test_mulDiv(wrapper, a, b, c, d, roundUp, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.mulDiv(a, b, c, d, roundUp)
    result = tx.return_value
    if a * b * c != 0:
        if d == 0:
            assert result == (1 << 216) - 1
        else:
            if roundUp:
                assert result == min(ceiling(Integer(a * b * c) / (d << 143)), (1 << 216) - 1)
            else:
                assert result == min(floor(Integer(a * b * c) / (d << 143)), (1 << 216) - 1)

@pytest.mark.parametrize('a', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('b', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('c', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('d', [value1, value2 >> 128, value2 // 7, value2 // 5, value2 // 3, value2])
@pytest.mark.parametrize('roundUp', [False, True])
def test_mulDiv(wrapper, a, b, c, d, roundUp, request, worker_id):
    logTest(request, worker_id)
    
    if roundUp:
        _result = ceiling(Integer(a * b * c) / (d << 111))
    else:
        _result = floor(Integer(a * b * c) / (d << 111))

    e = d
    while e % 2 != 1:
        e = e // 2
    tx = wrapper.mulDiv(a, b, c, d, pow(e, -1, 2 ** 256), roundUp)
    result, overflow = tx.return_value

    if _result < (1 << 255):
        assert overflow == False
        assert result == _result
    else:
        assert overflow == True

@pytest.mark.parametrize('value', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('numerator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('denominator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
def test_mulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if denominator != 0:
        _result = (value * numerator) // denominator
        if _result < (1 << 256):
            tx = wrapper.mulDiv(value, numerator, denominator)
            result = tx.return_value
            assert result == _result

@pytest.mark.parametrize('value', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('numerator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('denominator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
def test_mulDivRoundUp(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if denominator != 0:
        _result = 0 - ((0 - (value * numerator)) // denominator)
        if _result < (1 << 256):
            tx = wrapper.mulDivRoundUp(value, numerator, denominator)
            result = tx.return_value
            assert result == _result

@pytest.mark.parametrize('value', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('numerator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('denominator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
def test_safeMulDiv(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if denominator != 0:
        _result = (value * numerator) // denominator
        if _result < (1 << 256):
            tx = wrapper.safeMulDiv(value, numerator, denominator)
            result = tx.return_value
            assert result == _result
        else:
            with brownie.reverts('MulDivOverflow: ' + str(value) + ', ' + str(numerator) + ', ' + str(denominator)):
                tx = wrapper.safeMulDiv(value, numerator, denominator)
    else:
        with brownie.reverts('MulDivOverflow: ' + str(value) + ', ' + str(numerator) + ', ' + str(denominator)):
            tx = wrapper.safeMulDiv(value, numerator, denominator)

@pytest.mark.parametrize('value', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('numerator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
@pytest.mark.parametrize('denominator', [0, value2 // 5, value2 // 3, value4 // 5, value4 // 3, value4])
def test_safeMulDivRoundUp(wrapper, value, numerator, denominator, request, worker_id):
    logTest(request, worker_id)
    
    if denominator != 0:
        _result = 0 - ((0 - (value * numerator)) // denominator)
        if _result < (1 << 256):
            tx = wrapper.safeMulDivRoundUp(value, numerator, denominator)
            result = tx.return_value
            assert result == _result
        else:
            with brownie.reverts('MulDivOverflow: ' + str(value) + ', ' + str(numerator) + ', ' + str(denominator)):
                tx = wrapper.safeMulDivRoundUp(value, numerator, denominator)
    else:
        with brownie.reverts('MulDivOverflow: ' + str(value) + ', ' + str(numerator) + ', ' + str(denominator)):
            tx = wrapper.safeMulDiv(value, numerator, denominator)