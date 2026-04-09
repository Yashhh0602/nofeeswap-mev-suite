# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import chain, accounts, SentinelCallsWrapper, MockSentinel2
from eth_abi import encode
from Nofee import logTest, address0

maxHookInputByteCount = 0xFFF

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

portion0 = 0x000000000000
portion1 = 0x400000000000
portion2 = 0x800000000000
portion3 = 0xFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return SentinelCallsWrapper.deploy({'from': accounts[0]})

def test_invokeSentinelGetGrowthPortionsNull(wrapper):
    tx = wrapper._invokeSentinelGetGrowthPortions(address0, b'')
    maxPoolGrowthPortion, protocolGrowthPortion = tx.return_value
    assert maxPoolGrowthPortion == portion3
    assert protocolGrowthPortion == portion3

@pytest.mark.parametrize('maxPoolGrowthPortion', [portion0, portion1, portion2, portion3])
@pytest.mark.parametrize('protocolGrowthPortion', [portion0, portion1, portion2, portion3])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('byteCount', [0, maxHookInputByteCount // 2, maxHookInputByteCount])
@pytest.mark.parametrize('reverting', [False, True])
def test_invokeSentinelGetGrowthPortions(wrapper, maxPoolGrowthPortion, protocolGrowthPortion, content, byteCount, reverting, request, worker_id):
    logTest(request, worker_id)
    
    sentinel = MockSentinel2.deploy({'from': accounts[0]})
    dataBytes = encode(['uint256'] * (byteCount + 1), [byteCount] + [content] * byteCount)[0 : byteCount + 32]
    sentinel.setValues(maxPoolGrowthPortion, protocolGrowthPortion, 0, 0, reverting, dataBytes)

    if reverting:
        with brownie.reverts('Unknown typed error: 0x' + str(dataBytes.hex())):
            tx = wrapper._invokeSentinelGetGrowthPortions(sentinel, b'')
        chain.undo()
    else:
        tx = wrapper._invokeSentinelGetGrowthPortions(sentinel, dataBytes)
        tx.events['(unknown)']['data'].hex() == dataBytes.hex()
        _maxPoolGrowthPortion, _protocolGrowthPortion = tx.return_value
        assert _maxPoolGrowthPortion == maxPoolGrowthPortion
        assert _protocolGrowthPortion == protocolGrowthPortion
        chain.undo()
    
    chain.undo()
    chain.undo()

@pytest.mark.parametrize('badSelector', [False, True])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('byteCount', [0, maxHookInputByteCount // 2, maxHookInputByteCount])
@pytest.mark.parametrize('reverting', [False, True])
def test_invokeAuthorizeInitialization(wrapper, badSelector, content, byteCount, reverting, request, worker_id):
    logTest(request, worker_id)
    
    sentinel = MockSentinel2.deploy({'from': accounts[0]})
    dataBytes = encode(['uint256'] * (byteCount + 1), [byteCount] + [content] * byteCount)[0 : byteCount + 32]

    if badSelector:
        selector = (12).to_bytes(4, 'big')
    else:
        selector = sentinel.authorizeInitialization.signature

    sentinel.setValues(
        0,
        0,
        selector,
        0,
        reverting,
        dataBytes
    )

    if reverting:
        with brownie.reverts('Unknown typed error: 0x' + str(dataBytes.hex())):
            tx = wrapper._invokeAuthorizeInitialization(sentinel, b'')
        chain.undo()
    else:
        if badSelector:
            with brownie.reverts('InvalidSentinelResponse: ' + str(selector)):
                tx = wrapper._invokeAuthorizeInitialization(sentinel, dataBytes)
        else:
            tx = wrapper._invokeAuthorizeInitialization(sentinel, dataBytes)
            tx.events['(unknown)']['data'].hex() == dataBytes.hex()
        chain.undo()
    
    chain.undo()
    chain.undo()

@pytest.mark.parametrize('badSelector', [False, True])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('byteCount', [0, maxHookInputByteCount // 2, maxHookInputByteCount])
@pytest.mark.parametrize('reverting', [False, True])
def test_invokeAuthorizeModificationOfPoolGrowthPortion(wrapper, badSelector, content, byteCount, reverting, request, worker_id):
    logTest(request, worker_id)
    
    sentinel = MockSentinel2.deploy({'from': accounts[0]})
    dataBytes = encode(['uint256'] * (byteCount + 1), [byteCount] + [content] * byteCount)[0 : byteCount + 32]

    if badSelector:
        selector = (12).to_bytes(4, 'big')
    else:
        selector = sentinel.authorizeModificationOfPoolGrowthPortion.signature

    sentinel.setValues(
        0,
        0,
        0,
        selector,
        reverting,
        dataBytes
    )

    if reverting:
        with brownie.reverts('Unknown typed error: 0x' + str(dataBytes.hex())):
            tx = wrapper._invokeAuthorizeModificationOfPoolGrowthPortion(sentinel, b'')
        chain.undo()
    else:
        if badSelector:
            with brownie.reverts('InvalidSentinelResponse: ' + str(selector)):
                tx = wrapper._invokeAuthorizeModificationOfPoolGrowthPortion(sentinel, dataBytes)
        else:
            tx = wrapper._invokeAuthorizeModificationOfPoolGrowthPortion(sentinel, dataBytes)
            tx.events['(unknown)']['data'].hex() == dataBytes.hex()
        chain.undo()
    
    chain.undo()
    chain.undo()