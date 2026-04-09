# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, StorageWrapper
from sympy import Integer, floor, exp
from eth_abi import encode
from Nofee import logTest, _staticParams_, _endOfStaticParams_, address0, toInt, keccak256, keccakPacked, twosComplement
from Tag_test import tag0, tag1, tag2, tag3

accruedMax = (1 << 231) - 1

address1 = '0x0000000000000000000000000000000000000001'
address2 = '0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F'
address3 = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

portion0 = 0x000000000000
portion1 = 0x400000000000
portion2 = 0x800000000000
portion3 = 0xFFFFFFFFFFFF

balance0 = 0x00000000000000000000000000000000
balance1 = 0x00000000000000000000000000000001
balance2 = 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance5 = 0 - 0x00000000000000000000000000000001
balance6 = 0 - 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance7 = 0 - 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance8 = 0 - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

storageSlot0 = 0x0000000000000000000000000000000000000000000000000000000000000000
storageSlot1 = 0x0000000000000000000000000000000000000000000000000000000000000001
storageSlot2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
storageSlot3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
storageSlot4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

ratio0 = 0x000000
ratio1 = 0x400000
ratio2 = 0x800000
ratio3 = 0xFFFFFF

accrued0 = 0x0000000000000000000000000000000000000000000000000000000000000000
accrued1 = 0x0000000000000000000000000000000080000000000000000000000000000000
accrued2 = 0x7807F807F807F807F807F807F807F80780000000000000000000000000000000
accrued3 = 0x47FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000000000000000000000000000
accrued4 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80000000000000000000000000000000

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF

pointer0 = 0x0000
pointer1 = 0xF00F
pointer2 = 0xFFFF

integral0 = 0x000000000000000000000000000000000000000000000000000000
integral1 = 0xFFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
integral2 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

curve0 = 0x0550550550550550550550550550550550550550550550550550550550550550
curve1 = 0x1001001001001001001001001001001001001001001001001001001001001001
curve2 = 0x7CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC77CC7
curve3 = 0x8BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB88BB8
curve4 = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return StorageWrapper.deploy({'from': accounts[0]})

def test_protocolSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._protocolSlot()
    protocolSlot = tx.return_value
    assert protocolSlot == keccak256('protocol') - 1

def test_sentinelSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._sentinelSlot()
    sentinelSlot = tx.return_value
    assert sentinelSlot == keccak256('sentinel') - 1

@pytest.mark.parametrize('protocol', [value0, value1, value2, value3, value4])
def test_writeProtocol(wrapper, protocol, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the content of the protocol slot is written correctly.
    tx = wrapper._writeProtocol(protocol)
    protocolResult = tx.return_value
    assert protocolResult == protocol

@pytest.mark.parametrize('protocol', [value0, value1, value2, value3, value4])
def test_readProtocol(wrapper, protocol, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the content of the protocol slot is read correctly.
    tx = wrapper._readProtocol(protocol)
    result = tx.return_value
    assert result == protocol

@pytest.mark.parametrize('protocol', [value0, value1, value2, value3, value4])
def test_getProtocolOwner(wrapper, protocol, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the content of the protocol slot is parsed correctly.
    tx = wrapper._getProtocolOwner(protocol)
    protocolOwner = tx.return_value
    assert toInt(protocolOwner) == protocol % (1 << 160)

@pytest.mark.parametrize('protocol', [value0, value1, value2, value3, value4])
def test_getGrowthPortions(wrapper, protocol, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the content of the protocol slot is parsed correctly.
    tx = wrapper._getGrowthPortions(protocol)
    maxPoolGrowthPortion, protocolGrowthPortion = tx.return_value
    assert maxPoolGrowthPortion == protocol >> 208
    assert protocolGrowthPortion == (protocol >> 160) % (1 << 48)

@pytest.mark.parametrize('sentinel', [address0, address1, address2, address3])
def test_writeSentinel(wrapper, sentinel, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the sentinel contract is written correctly.
    tx = wrapper._writeSentinel(sentinel)
    sentinelResult = tx.return_value
    assert sentinelResult == sentinel

def test_singleBalanceSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._singleBalanceSlot()
    singleBalanceSlot = tx.return_value
    assert singleBalanceSlot == (keccak256('singleBalance') - 1) % (1 << 96)

@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
@pytest.mark.parametrize('tag', [tag0, tag1, tag2, tag3])
def test_getSingleBalanceSlot(wrapper, owner, tag, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to single balances are calculated correctly.
    tx = wrapper._getSingleBalanceSlot(owner, tag)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'address', 'uint96'], [tag, owner, (keccak256('singleBalance') - 1) % (1 << 96)])

@pytest.mark.parametrize('currentBalance', [balance0, balance1, balance2, balance4])
@pytest.mark.parametrize('owner', [address0, address2])
@pytest.mark.parametrize('tag', [tag0, tag2])
@pytest.mark.parametrize('amount', [balance0, balance1, balance2, balance4, value0, value1, value2, value3])
def test_incrementBalance(wrapper, currentBalance, owner, tag, amount, request, worker_id):
    logTest(request, worker_id)
    
    # Check if single balances are incremented correctly.
    if currentBalance + amount < 2 ** 128:
        tx = wrapper._incrementBalance(currentBalance, owner, tag, amount)
        newBalance = tx.return_value
        assert newBalance == currentBalance + amount
        assert tx.events['Transfer']['from'] == address0
        assert tx.events['Transfer']['to'] == owner
        assert tx.events['Transfer']['tag'] == tag
        assert tx.events['Transfer']['amount'] == amount
    else:
        with brownie.reverts('BalanceOverflow: ' + str(currentBalance + amount)):
            tx = wrapper._incrementBalance(currentBalance, owner, tag, amount)

def test_doubleBalanceSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._doubleBalanceSlot()
    doubleBalanceSlot = tx.return_value
    assert doubleBalanceSlot == (keccak256('doubleBalance') - 1) % (1 << 96)

@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
@pytest.mark.parametrize('tag0', [tag0, tag1, tag2, tag3])
@pytest.mark.parametrize('tag1', [tag0, tag1, tag2, tag3])
def test_getDoubleBalanceSlot(wrapper, owner, tag0, tag1, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to double balances are calculated correctly.
    tx = wrapper._getDoubleBalanceSlot(owner, tag0, tag1)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint256', 'address', 'uint96'], [tag0, tag1, owner, (keccak256('doubleBalance') - 1) % (1 << 96)])

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_readDoubleBalance(wrapper, storageSlot, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to double balances are read correctly.
    tx = wrapper._readDoubleBalance(storageSlot, content)
    amount0, amount1 = tx.return_value
    assert amount0 == content % (1 << 128)
    assert amount1 == content >> 128

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('amount0', [balance0, balance1, balance2, balance3, balance4])
@pytest.mark.parametrize('amount1', [balance0, balance1, balance2, balance3, balance4])
def test_writeDoubleBalance(wrapper, storageSlot, amount0, amount1, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to double balances are written correctly.
    tx = wrapper._writeDoubleBalance(storageSlot, amount0, amount1)
    content = tx.return_value
    assert content == (amount1 << 128) + amount0

def test_totalSupplySlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._totalSupplySlot()
    totalSupplySlot = tx.return_value
    assert totalSupplySlot == (keccak256('totalSupply') - 1) % (1 << 128)

@pytest.mark.parametrize('currentTotalSupply', [balance0, balance1, balance2, balance4])
@pytest.mark.parametrize('shares', [balance0, balance1, balance2, balance4, balance5, balance6, balance7, balance8])
@pytest.mark.parametrize('qMin', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qMax', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_updateTotalSupply(wrapper, currentTotalSupply, shares, qMin, qMax, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if total supply is incremented correctly.
    storageSlot = keccakPacked(['uint256', 'uint64', 'uint64', 'uint128'], [poolId, qMin, qMax, (keccak256('totalSupply') - 1) % (1 << 128)])
    newTotalSupply = currentTotalSupply + shares
    if 0 <= newTotalSupply and newTotalSupply < 2 ** 128:
        tx = wrapper._updateTotalSupply(storageSlot, currentTotalSupply, poolId, qMin, qMax, shares)
        result = tx.return_value
        assert result == newTotalSupply
    else:
        with brownie.reverts('BalanceOverflow: ' + str(twosComplement(newTotalSupply))):
            tx = wrapper._updateTotalSupply(storageSlot, currentTotalSupply, poolId, qMin, qMax, shares)

def test_isOperatorSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._isOperatorSlot()
    isOperatorSlot = tx.return_value
    assert isOperatorSlot == (keccak256('isOperator') - 1) % (1 << 96)

@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
@pytest.mark.parametrize('spender', [address0, address1, address2, address3])
def test_getIsOperatorSlot(wrapper, owner, spender, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to double balances are calculated correctly.
    tx = wrapper._getIsOperatorSlot(owner, spender)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['address', 'address', 'uint96'], [spender, owner, (keccak256('isOperator') - 1) % (1 << 96)])

def test_allowanceSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._allowanceSlot()
    allowanceSlot = tx.return_value
    assert allowanceSlot == (keccak256('allowance') - 1) % (1 << 96)

@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
@pytest.mark.parametrize('spender', [address0, address1, address2, address3])
@pytest.mark.parametrize('tag', [tag0, tag1, tag2, tag3])
def test_getAllowanceSlot(wrapper, owner, spender, tag, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to allowances are calculated correctly.
    tx = wrapper._getAllowanceSlot(owner, spender, tag)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'address', 'address', 'uint96'], [tag, spender, owner, (keccak256('allowance') - 1) % (1 << 96)])

def test_poolOwnerSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._poolOwnerSlot()
    poolOwnerSlot = tx.return_value
    assert poolOwnerSlot == (keccak256('poolOwner') - 1) % (1 << 128)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_getPoolOwnerSlot(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to pool owners are calculated correctly.
    tx = wrapper._getPoolOwnerSlot(poolId)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('poolOwner') - 1) % (1 << 128)])

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
def test_readPoolOwner(wrapper, storageSlot, owner, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to pool owners are read correctly.
    tx = wrapper._readPoolOwner(storageSlot, owner)
    ownerResult = tx.return_value
    assert ownerResult == owner

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
def test_writePoolOwner(wrapper, storageSlot, owner, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to pool owners are written correctly.
    tx = wrapper._writePoolOwner(storageSlot, owner)
    ownerResult = tx.return_value
    assert ownerResult == toInt(owner)

def test_accruedParamsSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._accruedParamsSlot()
    accruedParamsSlot = tx.return_value
    assert accruedParamsSlot == (keccak256('accruedParams') - 1) % (1 << 128)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_getAccruedParamsSlot(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to accrued parameters are calculated correctly.
    tx = wrapper._getAccruedParamsSlot(poolId)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('accruedParams') - 1) % (1 << 128)])

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_readAccruedParams(wrapper, poolId, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to accrued parameters are read correctly.
    tx = wrapper._readAccruedParams(poolId, content)
    poolRatio0, poolRatio1, accrued0, accrued1 = tx.return_value
    assert accrued0 == (content % (1 << 104)) << 127
    assert accrued1 == ((content >> 104) % (1 << 104)) << 127
    assert poolRatio0 == (content >> 208) % (1 << 24)
    assert poolRatio1 == content >> 232

def test_growthMultiplierSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._growthMultiplierSlot()
    growthMultiplierSlot = tx.return_value
    assert growthMultiplierSlot == (keccak256('growthMultiplier') - 1) % (1 << 64)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('qBoundary', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
def test_getGrowthMultiplierSlot(wrapper, poolId, qBoundary, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to growth multipliers are calculated correctly.
    tx = wrapper._getGrowthMultiplierSlot(poolId, qBoundary)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint64', 'uint64'], [poolId, qBoundary, (keccak256('growthMultiplier') - 1) % (1 << 64)])

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_readGrowthMultiplier(wrapper, storageSlot, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to growth multipliers are read correctly.
    tx = wrapper._readGrowthMultiplier(storageSlot, content)
    growthMultiplier = tx.return_value
    assert growthMultiplier == content

@pytest.mark.parametrize('qSpacing', [logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qBoundary', [logPrice1, logPrice2, logPrice3, logPrice4])
def test_calculateGrowthMultiplier0(wrapper, qSpacing, qBoundary, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the growth multipliers that face +oo are calculated correctly.
    growthMultiplier = floor(((2 ** 208) * exp(- Integer(qBoundary - (2 ** 63)) / (2 ** 60))) / (1 - exp(- Integer(qSpacing) / (2 ** 60))))
    if growthMultiplier < 2 ** 256:
        tx = wrapper._calculateGrowthMultiplier0(qSpacing, qBoundary)
        growthMultiplierResult = tx.return_value
        assert abs(growthMultiplierResult - growthMultiplier) < (1 << 10)

@pytest.mark.parametrize('qSpacing', [logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qBoundary', [logPrice1, logPrice2, logPrice3, logPrice4])
def test_calculateGrowthMultiplier1(wrapper, qSpacing, qBoundary, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the growth multipliers that face -oo are calculated correctly.
    growthMultiplier = floor(((2 ** 208) * exp(+ Integer(qBoundary - (2 ** 63)) / (2 ** 60))) / (1 - exp(- Integer(qSpacing) / (2 ** 60))))
    if growthMultiplier < 2 ** 256:
        tx = wrapper._calculateGrowthMultiplier1(qSpacing, qBoundary)
        growthMultiplierResult = tx.return_value
        assert abs(growthMultiplierResult - growthMultiplier) < (1 << 10)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value4])
@pytest.mark.parametrize('qSpacing', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('qBoundary', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('growthMultiplier', [value0, value1, value2, value4])
def test_calculateGrowthMultiplier0(wrapper, poolId, qSpacing, qBoundary, growthMultiplier, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the growth multipliers that face +oo are calculated correctly.
    tx = wrapper._calculateGrowthMultiplier0(poolId, qSpacing, qBoundary, growthMultiplier)
    growthMultiplierResult, growthMultiplierStorage = tx.return_value
    if growthMultiplier != 0:
        assert growthMultiplierResult == growthMultiplier
        assert growthMultiplierStorage == growthMultiplier
    else:
        growthMultiplierTrue = floor(((2 ** 208) * exp(- Integer(qBoundary - (2 ** 63)) / (2 ** 60))) / (1 - exp(- Integer(qSpacing) / (2 ** 60))))
        if growthMultiplierTrue < 2 ** 256:
            assert abs(growthMultiplierResult - growthMultiplierTrue) < (1 << 10)    
            assert abs(growthMultiplierStorage - growthMultiplierTrue) < (1 << 10)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value4])
@pytest.mark.parametrize('qSpacing', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('qBoundary', [logPrice1, logPrice2, logPrice4])
@pytest.mark.parametrize('growthMultiplier', [value0, value1, value2, value4])
def test_calculateGrowthMultiplier1(wrapper, poolId, qSpacing, qBoundary, growthMultiplier, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the growth multipliers that face -oo are calculated correctly.
    tx = wrapper._calculateGrowthMultiplier1(poolId, qSpacing, qBoundary, growthMultiplier)
    growthMultiplierResult, growthMultiplierStorage = tx.return_value
    if growthMultiplier != 0:
        assert growthMultiplierResult == growthMultiplier
        assert growthMultiplierStorage == growthMultiplier
    else:
        growthMultiplierTrue = floor(((2 ** 208) * exp(+ Integer(qBoundary - (2 ** 63)) / (2 ** 60))) / (1 - exp(- Integer(qSpacing) / (2 ** 60))))
        if growthMultiplierTrue < 2 ** 256:
            assert abs(growthMultiplierResult - growthMultiplierTrue) < (1 << 10)
            assert abs(growthMultiplierStorage - growthMultiplierTrue) < (1 << 10)

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('growthMultiplier', [value0, value1, value2, value3, value4])
def test_writeGrowthMultiplier(wrapper, storageSlot, growthMultiplier, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the growth multipliers are written correctly.
    tx = wrapper._writeGrowthMultiplier(storageSlot, growthMultiplier)
    content = tx.return_value
    assert content == growthMultiplier

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('qLower', [logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qUpper', [logPrice1, logPrice2, logPrice3, logPrice4])
def test_writeGrowthMultipliers(wrapper, poolId, qLower, qUpper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the growth multipliers are written correctly.
    if qLower != qUpper:
        if qLower > qUpper:
            qLower, qUpper = qUpper, qLower
        qSpacing = qUpper - qLower
        growthMultiplierLower = floor(((2 ** 208) * exp(+ Integer(qLower - (2 ** 63)) / (2 ** 60))) / (1 - exp(- Integer(qSpacing) / (2 ** 60))))
        growthMultiplierUpper = floor(((2 ** 208) * exp(- Integer(qUpper - (2 ** 63)) / (2 ** 60))) / (1 - exp(- Integer(qSpacing) / (2 ** 60))))
        if growthMultiplierLower < 2 ** 256 and growthMultiplierUpper < 2 ** 256:
            tx = wrapper._writeGrowthMultipliers(poolId, qUpper - qLower, qLower, qUpper)
            growthMultiplierLowerResult, growthMultiplierUpperResult = tx.return_value
            assert abs(growthMultiplierLowerResult - growthMultiplierLower) < (1 << 10)
            assert abs(growthMultiplierUpperResult - growthMultiplierUpper) < (1 << 10)

def test_sharesGrossSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._sharesGrossSlot()
    sharesGrossSlot = tx.return_value
    assert sharesGrossSlot == (keccak256('sharesGross') - 1) % (1 << 128)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_getSharesGrossSlot(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to shares gross values are calculated correctly.
    tx = wrapper._getSharesGrossSlot(poolId)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('sharesGross') - 1) % (1 << 128)])

def test_sharesDeltaSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._sharesDeltaSlot()
    sharesDeltaSlot = tx.return_value
    assert sharesDeltaSlot == (keccak256('sharesDelta') - 1) % (1 << 64)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('qBoundary', [logPrice1, logPrice2, logPrice3, logPrice4])
def test_getSharesDeltaSlot(wrapper, poolId, qBoundary, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to shares delta values are calculated correctly.
    tx = wrapper._getSharesDeltaSlot(poolId, qBoundary)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint64', 'uint64'], [poolId, qBoundary, (keccak256('sharesDelta') - 1) % (1 << 64)])

@pytest.mark.parametrize('storageSlot', [storageSlot0, storageSlot1, storageSlot2, storageSlot3, storageSlot4])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_readSharesDelta(wrapper, storageSlot, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to shares delta values are read correctly.
    tx = wrapper._readSharesDelta(storageSlot, content)
    sharesDelta = tx.return_value
    assert twosComplement(sharesDelta) == content

def test_dynamicParamsSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._dynamicParamsSlot()
    sharesDeltaSlot = tx.return_value
    assert sharesDeltaSlot == (keccak256('dynamicParams') - 1) % (1 << 128)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_getDynamicParamsSlot(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to dynamic parameters are calculated correctly.
    tx = wrapper._getDynamicParamsSlot(poolId)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('dynamicParams') - 1) % (1 << 128)])
        
def test_curveSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._curveSlot()
    curveSlot = tx.return_value
    assert curveSlot == (keccak256('curve') - 1) % (1 << 128)

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_getCurveSlot(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the storage slots dedicated to curve are calculated correctly.
    tx = wrapper._getCurveSlot(poolId)
    storageSlot = tx.return_value
    assert storageSlot == keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('curve') - 1) % (1 << 128)])

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
def test_readBoundaries(wrapper, poolId, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the curve boundaries are read correctly.
    tx = wrapper._readBoundaries(poolId, content)
    qLower, qUpper = tx.return_value
    _qLower = (content >> 192)
    _qUpper = (content >> 128) % (1 << 64)
    if _qLower > _qUpper:
        _qLower, _qUpper = _qUpper, _qLower
    assert _qLower == qLower
    assert _qUpper == qUpper

@pytest.mark.parametrize('poolId', [value0, value1, value2, value4])
@pytest.mark.parametrize('kernelLength', [1, 10, 25, 50])
@pytest.mark.parametrize('content', [value2, value3, value4])
def test_writeStaticParams(wrapper, poolId, kernelLength, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the static parameters are written correctly.

    storagePointer = keccakPacked(
        ['uint256', 'uint256', 'uint256'],
        [poolId, kernelLength, content]
    )

    contentLength = 64 * (kernelLength - 1) + _endOfStaticParams_ - _staticParams_
    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]

    storageAddress = keccakPacked(
        ['uint16', 'uint160', 'uint8'],
        [
            0xd694,
            keccakPacked(
                ['uint8', 'address', 'uint256', 'uint256'],
                [
                    0xFF,
                    wrapper.address,
                    keccakPacked(['uint256', 'uint256'], [poolId, storagePointer]),
                    0xF779EDCBDC615C777A4CB2BEE1BF733055AA41FF7247837D0CD548565F65D034
                ]
            ) % (1 << 160),
            0x01
        ]
    ) % (1 << 160)

    tx = wrapper._writeStaticParams(poolId, kernelLength, storagePointer, storageAddress, contentBytes)
    contentResult = tx.return_value
    assert contentResult.hex() == '00' + contentBytes.hex()

@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('storagePointer', [value0, value1, value2, value3, value4])
def test_getStaticParamsStorageAddress0(wrapper, poolId, storagePointer, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the static parameters storage address is calculated correctly.

    _storageAddress = keccakPacked(
        ['uint16', 'uint160', 'uint8'],
        [
            0xd694,
            keccakPacked(
                ['uint8', 'address', 'uint256', 'uint256'],
                [
                    0xFF,
                    wrapper.address,
                    keccakPacked(['uint256', 'uint256'], [poolId, storagePointer]),
                    0xF779EDCBDC615C777A4CB2BEE1BF733055AA41FF7247837D0CD548565F65D034
                ]
            ) % (1 << 160),
            0x01
        ]
    ) % (1 << 160)

    tx = wrapper._getStaticParamsStorageAddress(poolId, storagePointer)
    storageAddress = tx.return_value
    assert toInt(storageAddress) == _storageAddress

@pytest.mark.parametrize('nofeeswap', [address0, address1, address3])
@pytest.mark.parametrize('poolId', [value0, value1, value2, value4])
@pytest.mark.parametrize('storagePointer', [value0, value1, value2, value4])
def test_getStaticParamsStorageAddress1(wrapper, nofeeswap, poolId, storagePointer, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the static parameters storage address is calculated correctly.

    _storageAddress = keccakPacked(
        ['uint16', 'uint160', 'uint8'],
        [
            0xd694,
            keccakPacked(
                ['uint8', 'address', 'uint256', 'uint256'],
                [
                    0xFF,
                    nofeeswap,
                    keccakPacked(['uint256', 'uint256'], [poolId, storagePointer]),
                    0xF779EDCBDC615C777A4CB2BEE1BF733055AA41FF7247837D0CD548565F65D034
                ]
            ) % (1 << 160),
            0x01
        ]
    ) % (1 << 160)

    tx = wrapper._getStaticParamsStorageAddress(nofeeswap, poolId, storagePointer)
    storageAddress = tx.return_value
    assert toInt(storageAddress) == _storageAddress

@pytest.mark.parametrize('contentLength', [1, 10, 25, 50, 100, 200, 500])
@pytest.mark.parametrize('content', [value2, value3, value4])
def test_readStaticParams(wrapper, contentLength, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the static parameters are read correctly.

    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]
    tx = wrapper._readStaticParams(contentBytes)
    contentResult = tx.return_value
    if len(contentBytes.hex()) <= 2 * (_endOfStaticParams_ - _staticParams_):
        assert contentResult.hex() == contentBytes.hex() + '0' * (2 * (_endOfStaticParams_ - _staticParams_) - len(contentBytes.hex()))
    else:
        assert contentResult.hex() == contentBytes.hex()[0 : 2 * (_endOfStaticParams_ - _staticParams_)]

@pytest.mark.parametrize('contentLength', [500, 600, 700, 800, 900])
@pytest.mark.parametrize('content', [value2, value3, value4])
def test_readStaticParamsAndKernel(wrapper, contentLength, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the static parameters and kernel are read correctly.
    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]
    tx = wrapper._readStaticParamsAndKernel(contentBytes)
    contentResult = tx.return_value
    assert contentResult.hex() == contentBytes[0 : ((_endOfStaticParams_ - _staticParams_) + 64 * ((contentLength - (_endOfStaticParams_ - _staticParams_)) // 64))].hex()

@pytest.mark.parametrize('contentLength', [500, 600, 700, 800, 900])
@pytest.mark.parametrize('content', [value2, value3, value4])
def test_readKernelLength(wrapper, contentLength, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the kernel length is read correctly.
    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]
    tx = wrapper._readKernelLength(contentBytes)
    length = tx.return_value
    assert length == 1 + ((contentLength - (_endOfStaticParams_ - _staticParams_)) // 64)

@pytest.mark.parametrize('contentLength', [500, 600, 700, 800, 900])
@pytest.mark.parametrize('content', [value2, value3, value4])
def test_readKernel(wrapper, contentLength, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the kernel are read correctly.
    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]
    tx = wrapper._readKernel(contentBytes)
    contentResult = tx.return_value
    assert contentResult.hex() == contentBytes[(_endOfStaticParams_ - _staticParams_) : ((_endOfStaticParams_ - _staticParams_) + 64 * ((contentLength - (_endOfStaticParams_ - _staticParams_)) // 64))].hex()

@pytest.mark.parametrize('contentLength', [500, 600, 700, 800, 900])
@pytest.mark.parametrize('content', [value2, value3, value4])
def test_readKernel(wrapper, contentLength, content, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the kernel are read correctly.
    contentBytes = encode(['uint256'] * contentLength, [content] * contentLength)[0 : contentLength]
    tx = wrapper._readKernel(contentBytes)
    contentResult = tx.return_value
    assert contentResult.hex() == contentBytes[(_endOfStaticParams_ - _staticParams_) : ((_endOfStaticParams_ - _staticParams_) + 64 * ((contentLength - (_endOfStaticParams_ - _staticParams_)) // 64))].hex()