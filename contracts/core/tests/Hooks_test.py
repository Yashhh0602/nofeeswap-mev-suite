# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import chain, accounts, HooksWrapper, MockHook2
from eth_abi import encode
from Nofee import logTest, isPreInitialize, isPostInitialize, isPreMint, isMidMint, isPostMint, isPreBurn, isMidBurn, isPostBurn, isPreSwap, isMidSwap, isPostSwap, isPreDonate, isMidDonate, isPostDonate, isPreModifyKernel, isMidModifyKernel, isPostModifyKernel, isMutableKernel, isMutablePoolGrowthPortion, isDonateAllowed, toInt

maxHookInputByteCount = 0xFFF

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return HooksWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_invokeHook(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._getHook(poolId)
    hookAddress = tx.return_value
    assert toInt(hookAddress) == poolId % (1 << 160)

@pytest.mark.parametrize('returnSelector', [False, True])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('byteCount', [0, maxHookInputByteCount // 2, maxHookInputByteCount])
@pytest.mark.parametrize('reverting', [False, True])
def test_invokeHook(wrapper, returnSelector, content, byteCount, reverting, request, worker_id):
    logTest(request, worker_id)
    
    hook = MockHook2.deploy({'from': accounts[0]})
    dataBytes = encode(['uint256'] * (byteCount + 1), [byteCount] + [content] * byteCount)[0 : byteCount + 32]

    selector = hook.arbitrary.signature
    poolId = toInt(hook.address)

    hook.setValues(
        selector,
        reverting,
        returnSelector,
        dataBytes
    )

    if reverting:
        with brownie.reverts('Unknown typed error: 0x' + str(dataBytes.hex())):
            tx = wrapper._invokeHook(poolId, selector, b'')
    else:
        if returnSelector:
            tx = wrapper._invokeHook(poolId, selector, dataBytes)
            tx.events['(unknown)']['data'].hex() == dataBytes.hex()
        else:
            with brownie.reverts('Unknown typed error: 0x' + str(dataBytes.hex())):
                tx = wrapper._invokeHook(poolId, selector, dataBytes)

    chain.undo()
    chain.undo()
    chain.undo()

@pytest.mark.parametrize('poolId', [
    isPreInitialize,
    isPostInitialize,
    isPreMint,
    isMidMint,
    isPostMint,
    isPreBurn,
    isMidBurn,
    isPostBurn,
    isPreSwap,
    isMidSwap,
    isPostSwap,
    isPreDonate + isDonateAllowed,
    isMidDonate + isDonateAllowed,
    isPostDonate + isDonateAllowed,
    isPreModifyKernel + isMutableKernel,
    isMidModifyKernel + isMutableKernel,
    isPostModifyKernel + isMutableKernel,
    1,
    isDonateAllowed + 1,
    isMutablePoolGrowthPortion + 1,
    isMutableKernel + 1,
    isMutablePoolGrowthPortion + isMutableKernel + 1,
    isDonateAllowed + isMutableKernel + 1,
    isDonateAllowed + isMutablePoolGrowthPortion + 1,
    isDonateAllowed + isMutablePoolGrowthPortion + isMutableKernel + 1,
    isPreModifyKernel + 1,
    isMidModifyKernel + 1,
    isPostModifyKernel + 1,
    isPreDonate + 1,
    isMidDonate + 1,
    isPostDonate + 1
])
def test_validateFlags(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = wrapper._validateFlags(poolId)

def test_isPreInitialize(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPreInitialize(isPreInitialize)
    tx.return_value == True
    tx = wrapper._isPreInitialize(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPreInitialize(poolId)

def test_isPostInitialize(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPostInitialize(isPostInitialize)
    tx.return_value == True
    tx = wrapper._isPostInitialize(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPostInitialize(poolId)

def test_isPreMint(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPreMint(isPreMint)
    tx.return_value == True
    tx = wrapper._isPreMint(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPreMint(poolId)

def test_isMidMint(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMidMint(isMidMint)
    tx.return_value == True
    tx = wrapper._isMidMint(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isMidMint(poolId)

def test_isPostMint(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPostMint(isPostMint)
    tx.return_value == True
    tx = wrapper._isPostMint(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPostMint(poolId)

def test_isPreBurn(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPreBurn(isPreBurn)
    tx.return_value == True
    tx = wrapper._isPreBurn(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPreBurn(poolId)

def test_isMidBurn(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMidBurn(isMidBurn)
    tx.return_value == True
    tx = wrapper._isMidBurn(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isMidBurn(poolId)

def test_isPostBurn(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPostBurn(isPostBurn)
    tx.return_value == True
    tx = wrapper._isPostBurn(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPostBurn(poolId)

def test_isPreSwap(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPreSwap(isPreSwap)
    tx.return_value == True
    tx = wrapper._isPreSwap(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPreSwap(poolId)

def test_isMidSwap(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMidSwap(isMidSwap)
    tx.return_value == True
    tx = wrapper._isMidSwap(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isMidSwap(poolId)

def test_isPostSwap(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPostSwap(isPostSwap)
    tx.return_value == True
    tx = wrapper._isPostSwap(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPostSwap(poolId)

def test_isPreDonate(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPreDonate(isPreDonate)
    tx.return_value == True
    tx = wrapper._isPreDonate(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPreDonate(poolId)

def test_isMidDonate(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMidDonate(isMidDonate)
    tx.return_value == True
    tx = wrapper._isMidDonate(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isMidDonate(poolId)

def test_isPostDonate(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPostDonate(isPostDonate)
    tx.return_value == True
    tx = wrapper._isPostDonate(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPostDonate(poolId)

def test_isPreModifyKernel(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPreModifyKernel(isPreModifyKernel)
    tx.return_value == True
    tx = wrapper._isPreModifyKernel(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPreModifyKernel(poolId)

def test_isMidModifyKernel(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMidModifyKernel(isMidModifyKernel)
    tx.return_value == True
    tx = wrapper._isMidModifyKernel(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isMidModifyKernel(poolId)

def test_isPostModifyKernel(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isPostModifyKernel(isPostModifyKernel)
    tx.return_value == True
    tx = wrapper._isPostModifyKernel(0)
    tx.return_value == False
    hook = MockHook2.deploy({'from': accounts[0]})
    poolId = toInt(hook.address)
    wrapper.__isPostModifyKernel(poolId)

def test_isMutableKernel(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMutableKernel(isMutableKernel)
    tx.return_value == True
    tx = wrapper._isMutableKernel(0)
    tx.return_value == False

def test_isMutablePoolGrowthPortion(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isMutablePoolGrowthPortion(isMutablePoolGrowthPortion)
    tx.return_value == True
    tx = wrapper._isMutablePoolGrowthPortion(0)
    tx.return_value == False

def test_isDonateAllowed(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._isDonateAllowed(isDonateAllowed)
    tx.return_value == True
    tx = wrapper._isDonateAllowed(0)
    tx.return_value == False