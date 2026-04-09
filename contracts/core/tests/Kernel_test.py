# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, KernelWrapper
from sympy import Integer, floor, exp
from eth_abi.packed import encode_packed
from Nofee import logTest, thirtyTwoX59

maxKernelIndex = 0xFFF

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

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return KernelWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('kernelLength', [2, maxKernelIndex // 2, maxKernelIndex])
@pytest.mark.parametrize('kernel', [128, 1000, 10000])
def test_member(wrapper, content, kernelLength, kernel, request, worker_id):
    logTest(request, worker_id)
    
    kernelContent = 0
    for kk in range(4 * kernelLength):
        kernelContent = kernelContent << 250
        kernelContent = kernelContent + (content >> 6)

    kernelArray = []
    for kk in range(kernelLength - 1):
        kernelArray = kernelArray + [kernelContent % 256]
        kernelContent = kernelContent >> 256
        kernelArray = kernelArray + [kernelContent % 256]
        kernelContent = kernelContent >> 256

    height = [0] + [kernelArray[2 * kk] >> 240 for kk in range(kernelLength - 1)]
    logShift = [0] + [(kernelArray[2 * kk] >> 176) & 0xFFFFFFFFFFFFFFFF for kk in range(kernelLength - 1)]
    sqrtShift = [1 << 216] + [((kernelArray[2 * kk] % (1 << 176)) << 40) + (kernelArray[2 * kk + 1] >> 216) for kk in range(kernelLength - 1)]
    sqrtInverseShift = [0x0000000000000001E355BBAEE85CADA65F73F32E88FB3CC629B709109F57564D] + [kernelArray[2 * kk + 1] % (1 << 216) for kk in range(kernelLength - 1)]

    tx = wrapper._member(kernel, kernelArray)
    
    assert tx.events[0]['data'].hex() == encode_packed(['uint256'] * kernelLength, height).hex()
    assert tx.events[1]['data'].hex() == encode_packed(['uint256'] * kernelLength, logShift).hex()
    assert tx.events[2]['data'].hex() == encode_packed(['uint256'] * kernelLength, sqrtShift).hex()
    assert tx.events[3]['data'].hex() == encode_packed(['uint256'] * kernelLength, sqrtInverseShift).hex()

@pytest.mark.parametrize('kernel', [1000, 10000])
@pytest.mark.parametrize('resultant', [1000, 10000])
@pytest.mark.parametrize('basePrice', [1000, 10000])
@pytest.mark.parametrize('index', [10, 200])
@pytest.mark.parametrize('left', [False, True])
@pytest.mark.parametrize('memberHeight', [height0, height1, height2, height3, height4])
@pytest.mark.parametrize('memberLog', [logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('basePriceHeight', [height3])
@pytest.mark.parametrize('basePriceLog', [logPrice1, logPrice2, logPrice3, logPrice4])
def test_impose(wrapper, kernel, resultant, basePrice, index, left, memberHeight, memberLog, basePriceHeight, basePriceLog, request, worker_id):
    logTest(request, worker_id)
    
    sqrtMember = floor((2 ** 216) * exp(- Integer(memberLog) / (2 ** 60)))
    sqrtInverseMember = floor((2 ** 216) * exp(- 16 + Integer(memberLog) / (2 ** 60)))
    memberContent0 = (memberHeight << 240) + (memberLog << 176) + (sqrtMember >> 40)
    memberContent1 = ((sqrtMember % (1 << 40)) << 216) + sqrtInverseMember

    sqrtBasePrice = floor((2 ** 216) * exp(- Integer(basePriceLog) / (2 ** 60)))
    sqrtInverseBasePrice = floor((2 ** 216) * exp(- 16 + Integer(basePriceLog) / (2 ** 60)))
    basePriceContent0 = (basePriceHeight << 240) + (basePriceLog << 176) + (sqrtBasePrice >> 40)
    basePriceContent1 = ((sqrtBasePrice % (1 << 40)) << 216) + sqrtInverseBasePrice

    if (left and (basePriceLog > memberLog)) or (not(left) and (basePriceLog + memberLog < thirtyTwoX59)):
        heightResultant = memberHeight
        logResultant = basePriceLog - memberLog if left else basePriceLog + memberLog
        sqrtResultant = floor((2 ** 216) * exp(- Integer(logResultant) / (2 ** 60)))
        sqrtInverseResultant = floor((2 ** 216) * exp(- 16 + Integer(logResultant) / (2 ** 60)))

        tx = wrapper._impose(kernel, resultant, basePrice, index, left, memberContent0, memberContent1, basePriceContent0, basePriceContent1)
        resultantContent0, resultantContent1 = tx.return_value

        height = resultantContent0 >> 240
        logPrice = (resultantContent0 >> 176) % (1 << 64)
        sqrtPrice = ((resultantContent0 % (1 << 176)) << 40) + (resultantContent1 >> 216)
        sqrtInversePrice = resultantContent1 % (1 << 216)

        assert height == heightResultant
        assert logPrice == logResultant
        assert abs(sqrtPrice - sqrtResultant) < (1 << 32)
        assert abs(sqrtInversePrice - sqrtInverseResultant) < (1 << 32)