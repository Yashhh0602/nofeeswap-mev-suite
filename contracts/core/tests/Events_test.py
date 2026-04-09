# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, EventsWrapper
from eth_abi import encode
from Nofee import logTest, _poolId_, _endOfStaticParams_, _hookData_, _hookSelector_, _tag0_, _tag1_, _staticParams_, _endOfModifyPosition_, _modifyPositionInput_, _growth_, _curve_, _curveLength_, _poolGrowthPortion_, _maxPoolGrowthPortion_, toInt

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return EventsWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('hookData', [_endOfStaticParams_ + 2, _endOfStaticParams_ + 10, _endOfStaticParams_ + 200])
def test_emitInitializeEvent(wrapper, content, hookData, request, worker_id):
    logTest(request, worker_id)
    
    contentBytes = encode(['uint256'] * hookData, [content] * hookData)[0 : hookData - _hookSelector_]
    contentBytes = contentBytes[0 : _hookData_ - _hookSelector_] + hookData.to_bytes(32, 'big') + contentBytes[_hookData_ - _hookSelector_ + 32 : ]

    tx = wrapper._emitInitializeEvent(contentBytes)

    assert tx.events['Initialize']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ - _hookSelector_ + 32].hex())
    assert tx.events['Initialize']['tag0'] == toInt(contentBytes[_tag0_ - _hookSelector_ : _tag0_ - _hookSelector_ + 32].hex())
    assert tx.events['Initialize']['tag1'] == toInt(contentBytes[_tag1_ - _hookSelector_ : _tag1_ - _hookSelector_ + 32].hex())
    assert tx.events['Initialize']['data'].hex() == contentBytes[_staticParams_ - _hookSelector_ : hookData - _hookSelector_].hex()

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_emitModifyPositionEvent(wrapper, content, request, worker_id):
    logTest(request, worker_id)
    
    length = _endOfModifyPosition_
    contentBytes = encode(['uint256'] * length, [content] * length)[0 : length - _hookSelector_]

    tx = wrapper._emitModifyPositionEvent(contentBytes)

    zero = 0

    assert tx.events['ModifyPosition']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ - _hookSelector_ + 32].hex())
    assert tx.events['ModifyPosition']['caller'] == accounts[0].address
    assert encode(['bytes32'] * 6, tx.events['ModifyPosition']['data']).hex() == contentBytes[_modifyPositionInput_ - _hookSelector_ : _endOfModifyPosition_ - _hookSelector_].hex() + zero.to_bytes(16, 'big').hex()

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_emitDonateEvent(wrapper, content, request, worker_id):
    logTest(request, worker_id)
    
    length = 1760
    contentBytes = encode(['uint256'] * length, [content] * length)[0 : length - _hookSelector_]

    tx = wrapper._emitDonateEvent(contentBytes)

    zero = 0

    assert tx.events['Donate']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ - _hookSelector_ + 32].hex())
    assert tx.events['Donate']['caller'] == accounts[0].address
    assert tx.events['Donate']['data'].hex() == contentBytes[_growth_ - _hookSelector_ : _growth_ - _hookSelector_ + 16].hex() + zero.to_bytes(16, 'big').hex()

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('curve', [_endOfStaticParams_ + 2, _endOfStaticParams_ + 10, _endOfStaticParams_ + 200])
@pytest.mark.parametrize('curveLength', [2, 10, 50])
def test_emitSwapEvent(wrapper, content, curve, curveLength, request, worker_id):
    logTest(request, worker_id)
    
    length = curve + 8 * curveLength
    contentBytes = encode(['uint256'] * length, [content] * length)[0 : length - _hookSelector_]
    contentBytes = contentBytes[0 : _curve_ - _hookSelector_] + curve.to_bytes(32, 'big') + contentBytes[_curve_ - _hookSelector_ + 32 : ]
    contentBytes = contentBytes[0 : _curveLength_ - _hookSelector_] + curveLength.to_bytes(2, 'big') + contentBytes[_curveLength_ - _hookSelector_ + 2 : ]

    tx = wrapper._emitSwapEvent(contentBytes)

    assert tx.events['Swap']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ + 32 - _hookSelector_].hex())
    assert tx.events['Swap']['caller'] == accounts[0].address
    assert tx.events['Swap']['data'].hex() == contentBytes[length - _hookSelector_ - 16 : length - _hookSelector_].hex() + contentBytes[_growth_ - _hookSelector_ : _growth_ - _hookSelector_ + 16].hex()

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('hookData', [_endOfStaticParams_ + 2, _endOfStaticParams_ + 10, _endOfStaticParams_ + 200])
def test_emitModifyKernelEvent(wrapper, content, hookData, request, worker_id):
    logTest(request, worker_id)
    
    contentBytes = encode(['uint256'] * hookData, [content] * hookData)[0 : hookData - _hookSelector_]
    contentBytes = contentBytes[0 : _hookData_ - _hookSelector_] + hookData.to_bytes(32, 'big') + contentBytes[_hookData_ - _hookSelector_ + 32 : ]

    tx = wrapper._emitModifyKernelEvent(contentBytes)

    assert tx.events['ModifyKernel']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ - _hookSelector_ + 32].hex())
    assert tx.events['ModifyKernel']['caller'] == accounts[0].address
    assert tx.events['ModifyKernel']['data'].hex() == contentBytes[_staticParams_ - _hookSelector_ : hookData - _hookSelector_].hex()

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_emitModifyPoolGrowthPortionEvent(wrapper, content, request, worker_id):
    logTest(request, worker_id)
    
    length = _endOfStaticParams_
    contentBytes = encode(['uint256'] * length, [content] * length)[0 : length - _hookSelector_]

    tx = wrapper._emitModifyPoolGrowthPortionEvent(contentBytes)

    zero = 0

    assert tx.events['ModifyPoolGrowthPortion']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ + 32 - _hookSelector_].hex())
    assert tx.events['ModifyPoolGrowthPortion']['caller'] == accounts[0].address
    assert tx.events['ModifyPoolGrowthPortion']['data'].hex() == contentBytes[_poolGrowthPortion_ - _hookSelector_ : _poolGrowthPortion_ - _hookSelector_ + 6].hex() + zero.to_bytes(26, 'big').hex()

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_emitUpdateGrowthPortionsEvent(wrapper, content, request, worker_id):
    logTest(request, worker_id)
    
    length = _endOfStaticParams_
    contentBytes = encode(['uint256'] * length, [content] * length)[0 : length - _hookSelector_]

    tx = wrapper._emitUpdateGrowthPortionsEvent(contentBytes)

    zero = 0

    assert tx.events['UpdateGrowthPortions']['poolId'] == toInt(contentBytes[_poolId_ - _hookSelector_ : _poolId_ - _hookSelector_ + 32].hex())
    assert tx.events['UpdateGrowthPortions']['caller'] == accounts[0].address
    assert tx.events['UpdateGrowthPortions']['data'].hex() == contentBytes[_maxPoolGrowthPortion_ - _hookSelector_ : _maxPoolGrowthPortion_ - _hookSelector_ + 12].hex() + zero.to_bytes(20, 'big').hex()