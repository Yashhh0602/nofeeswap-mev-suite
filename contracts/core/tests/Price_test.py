# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, PriceWrapper
from sympy import Integer, floor, exp
from Nofee import logTest
from X15_test import oneX15
from X59_test import thirtyTwoX59, epsilonX59
from X216_test import oneX216

epsilonX15 = 1
epsilonX216 = 1

sampleX15 = 0xF00F
sampleX59 = 0xF00FF00FF00FF00F
sampleX216 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return PriceWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('logPrice', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
def test_storePrice0(wrapper, logPrice, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.storePrice(logPrice)
    logResult, sqrtResult, sqrtInverseResult = tx.return_value
    assert logResult == logPrice
    assert abs(sqrtResult - floor((2 ** 216) * exp(- Integer(logPrice) / (2 ** 60)))) <= 1
    assert abs(sqrtInverseResult - floor((2 ** 216) * exp(- 16 + Integer(logPrice) / (2 ** 60)))) <= 1

@pytest.mark.parametrize('logPrice', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
@pytest.mark.parametrize('sqrt', [epsilonX216, sampleX216, oneX216 - epsilonX216])
@pytest.mark.parametrize('sqrtInverse', [epsilonX216, sampleX216, oneX216 - epsilonX216])
def test_storePrice1(wrapper, logPrice, sqrt, sqrtInverse, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.storePrice(logPrice, sqrt, sqrtInverse)
    logResult, sqrtResult, sqrtInverseResult = tx.return_value
    assert logResult == logPrice
    assert sqrtResult == sqrt
    assert sqrtInverseResult == sqrtInverse

@pytest.mark.parametrize('height', [epsilonX15, sampleX15, oneX15 - epsilonX15])
@pytest.mark.parametrize('logPrice', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
@pytest.mark.parametrize('sqrt', [epsilonX216, sampleX216, oneX216 - epsilonX216])
@pytest.mark.parametrize('sqrtInverse', [epsilonX216, sampleX216, oneX216 - epsilonX216])
def test_storePrice2(wrapper, height, logPrice, sqrt, sqrtInverse, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.storePrice(height, logPrice, sqrt, sqrtInverse)
    heightResult, logResult, sqrtResult, sqrtInverseResult = tx.return_value
    assert heightResult == height
    assert logResult == logPrice
    assert sqrtResult == sqrt
    assert sqrtInverseResult == sqrtInverse

@pytest.mark.parametrize('height', [epsilonX15, sampleX15, oneX15 - epsilonX15])
def test_height(wrapper, height, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.height(height)
    assert tx.return_value == height

@pytest.mark.parametrize('logPrice', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
def test_log(wrapper, logPrice, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.log(logPrice)
    assert tx.return_value == logPrice

@pytest.mark.parametrize('sqrt', [epsilonX216, sampleX216, oneX216 - epsilonX216])
def test_sqrt(wrapper, sqrt, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.sqrt(sqrt, False)
    assert tx.return_value == sqrt

    tx = wrapper.sqrt(sqrt, True)
    assert tx.return_value == sqrt

@pytest.mark.parametrize('logPrice', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
@pytest.mark.parametrize('sqrt', [epsilonX216, sampleX216, oneX216 - epsilonX216])
@pytest.mark.parametrize('sqrtInverse', [epsilonX216, sampleX216, oneX216 - epsilonX216])
def test_copyPrice(wrapper, logPrice, sqrt, sqrtInverse, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.copyPrice(logPrice, sqrt, sqrtInverse)
    logResult, sqrtResult, sqrtInverseResult = tx.return_value
    assert logResult == logPrice
    assert sqrtResult == sqrt
    assert sqrtInverseResult == sqrtInverse

@pytest.mark.parametrize('height', [epsilonX15, sampleX15, oneX15 - epsilonX15])
@pytest.mark.parametrize('logPrice', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
@pytest.mark.parametrize('sqrt', [epsilonX216, sampleX216, oneX216 - epsilonX216])
@pytest.mark.parametrize('sqrtInverse', [epsilonX216, sampleX216, oneX216 - epsilonX216])
def test_copyPriceWithHeight(wrapper, height, logPrice, sqrt, sqrtInverse, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.copyPriceWithHeight(height, logPrice, sqrt, sqrtInverse)
    heightResult, logResult, sqrtResult, sqrtInverseResult = tx.return_value
    assert heightResult == height
    assert logResult == logPrice
    assert sqrtResult == sqrt
    assert sqrtInverseResult == sqrtInverse

@pytest.mark.parametrize('b0', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
@pytest.mark.parametrize('b1', [epsilonX59, sampleX59, thirtyTwoX59 - epsilonX59])
@pytest.mark.parametrize('c0', [epsilonX15, sampleX15, oneX15 - epsilonX15])
@pytest.mark.parametrize('c1', [epsilonX15, sampleX15, oneX15 - epsilonX15])
def test_segment(wrapper, b0, b1, c0, c1, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper.segment(b0, b1, c0, c1)
    b0Result, b1Result, c0Result, c1Result = tx.return_value
    assert b0Result == b0
    assert b1Result == b1
    assert c0Result == c0
    assert c1Result == c1