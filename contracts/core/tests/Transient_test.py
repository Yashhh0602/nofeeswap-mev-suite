# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, TransientWrapper
from Nofee import logTest, address0, keccak256, keccak, keccakPacked
from Tag_test import tag0, tag1, tag2, tag3

address1 = '0x0000000000000000000000000000000000000001'
address2 = '0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F'
address3 = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'

poolId0 = 0x0000000000000000000000000000000000000000000000000000000000000001
poolId1 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
poolId2 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

id0 = 0x0000000000000000000000000000000000000000000000000000000000000000
id1 = 0x0000000000000000000000000000000000000000000000000000000000000001
id2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
id3 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

reserve0 = 0x0000000000000000000000000000000000000000000000000000000000000000
reserve1 = 0x0000000000000000000000000000000000000000000000000000000000000001
reserve2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
reserve3 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

pointer0 = 0x0000000000000000000000000000000000000000000000000000000000000000
pointer1 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F

portion0 = 0x0000000000000000000000000000000000000000000000000000000000000000
portion1 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F

index0 = 0x0000000000000000000000000000000000000000000000000000000000000000
index1 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

balance0 = 0x00000000000000000000000000000000
balance1 = 0x00000000000000000000000000000001
balance2 = 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance5 = 0 - 0x00000000000000000000000000000001
balance6 = 0 - 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance7 = 0 - 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance8 = 0 - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return TransientWrapper.deploy({'from': accounts[0]})

def test_unlockTargetSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._unlockTargetSlot()
    unlockTargetSlot = tx.return_value
    assert unlockTargetSlot == keccak256('unlockTarget') - 1

def test_callerSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._callerSlot()
    callerSlot = tx.return_value
    assert callerSlot == keccak256('caller') - 1

@pytest.mark.parametrize('unlockTarget', [address0, address1, address2, address3])
@pytest.mark.parametrize('caller', [address0, address1, address2, address3])
def test_unlockTargetSlot(wrapper, unlockTarget, caller, request, worker_id):
    logTest(request, worker_id)
    
    # Check if 'unlockTarget' and 'caller' are set correctly by 'unlockProtocol'
    # and cleared by 'lockProtocol'.
    tx = wrapper._lockUnlockProtocol(unlockTarget, caller)
    unlockTargetResult0, callerResult0, unlockTargetResult1, callerResult1 = tx.return_value

    assert unlockTargetResult0 == unlockTarget
    assert callerResult0 == caller
    assert unlockTargetResult1 == address0
    assert callerResult1 == address0

@pytest.mark.parametrize('unlockTarget', [address0, address1, address2, address3])
@pytest.mark.parametrize('caller', [address0, address1, address2, address3])
def test_isProtocolUnlocked(wrapper, unlockTarget, caller, request, worker_id):
    logTest(request, worker_id)
    
    # Check if 'isProtocolUnlocked' prevents reentrancy.
    if caller == address0:
        with brownie.reverts('ProtocolIsLocked: '):
            tx = wrapper._isProtocolUnlocked(unlockTarget, caller)
    else:
        tx = wrapper._isProtocolUnlocked(unlockTarget, caller)

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2])
def test_getPoolLockSlot(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the transient storage slot dedicated to each pool is calculated correctly.
    tx = wrapper._getPoolLockSlot(poolId)
    transientSlot = tx.return_value
    assert transientSlot == keccak(['uint256', 'uint256'], [poolId, keccak256('unlockTarget') - 1])

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2])
def test_lockPoolRevert(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if 'lockPool' prevents reentrancy.
    with brownie.reverts('PoolIsLocked: ' + str(poolId)):
        tx = wrapper._lockPoolRevert(poolId)

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2])
def test_lockUnlockPool(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if 'lockPool' populates the corresponding transient storage slot correctly
    # and if 'unlockPool' clears it correctly.
    tx = wrapper._lockUnlockPool(poolId)
    content0, content1 = tx.return_value
    assert content0 == (1 << 256) - 1
    assert content1 == 0

def test_nonzeroAmountsSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._nonzeroAmountsSlot()
    nonzeroAmountsSlot = tx.return_value
    assert nonzeroAmountsSlot == keccak256('nonzeroAmounts') - 1

@pytest.mark.parametrize('increment', [0, 1, 10, 100])
@pytest.mark.parametrize('decrement', [0, 1, 10, 100])
def test_readNonzeroAmounts(wrapper, increment, decrement, request, worker_id):
    logTest(request, worker_id)
    
    # Check if 'incrementNonzeroAmounts' and 'decrementNonzeroAmounts' correctly
    # modify the content of 'nonzeroAmountsSlot'.
    tx = wrapper._readNonzeroAmounts(increment, decrement)
    nonzeroAmounts = tx.return_value
    assert nonzeroAmounts == (increment - decrement) % (1 << 256)

def test_transientBalanceSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._transientBalanceSlot()
    transientSlot = tx.return_value
    assert transientSlot == (keccak256('transientBalance') - 1) % (1 << 96)

@pytest.mark.parametrize('owner', [address0, address1, address2, address3])
@pytest.mark.parametrize('tag', [tag0, tag1, tag2, tag3])
def test_getTransientBalanceSlot(wrapper, owner, tag, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the transient storage slot dedicated to transient balances
    # are calculated correctly.
    tx = wrapper._getTransientBalanceSlot(owner, tag)
    transientSlot = tx.return_value
    assert transientSlot == keccakPacked(
        ['uint256', 'address', 'uint96'],
        [tag, owner, (keccak256('transientBalance') - 1) % (1 << 96)]
    )

def test_updateGetTransientBalance(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if 'updateTransientBalance' modifies the content of
    # 'transientBalanceSlot' and 'nonzeroAmountsSlot' correctly.
    tx = wrapper._updateGetTransientBalance(
        [address0, address1, address2, address3] + [address0, address1] * 4,
        [tag0, tag1, tag2] * 4,
        [- 2, 3, 7, (1 << 128) - 1] * 3
    )
    results, nonzeroAmounts = tx.return_value

    # address0, tag0, - 2
    # address1, tag1, + 3
    # address2, tag2, + 7
    # address3, tag0, - 1 + (1 << 128)
    # address0, tag1, - 2
    # address1, tag2, + 3
    # address0, tag0, + 7
    # address1, tag1, - 1 + (1 << 128)
    # address0, tag2, - 2
    # address1, tag0, + 3
    # address0, tag1, + 7
    # address1, tag2, - 1 + (1 << 128)

    assert results[0] == - 2 + 7
    assert results[1] == 3 + (1 << 128) - 1
    assert results[2] == 7
    assert results[3] == (1 << 128) - 1
    assert results[4] == - 2 + 7
    assert results[5] == 3 + (1 << 128) - 1
    assert results[6] == - 2 + 7
    assert results[7] == 3 + (1 << 128) - 1
    assert results[8] == - 2
    assert results[9] == 3
    assert results[10] == - 2 + 7
    assert results[11] == 3 + (1 << 128) - 1

    assert nonzeroAmounts == 8

def test_tokenSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._tokenSlot()
    transientSlot = tx.return_value
    assert transientSlot == keccak256('token') - 1

def test_tokenIdSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._tokenIdSlot()
    transientSlot = tx.return_value
    assert transientSlot == keccak256('tokenId') - 1

def test_reserveSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._reserveSlot()
    transientSlot = tx.return_value
    assert transientSlot == keccak256('reserve') - 1

@pytest.mark.parametrize('token', [address0, address1, address2, address3])
@pytest.mark.parametrize('id', [id0, id1, id2, id3])
@pytest.mark.parametrize('reserve', [reserve0, reserve1, reserve2, reserve3])
@pytest.mark.parametrize('multiToken', [False, True])
def test_writeReadReserve(wrapper, token, id, reserve, multiToken, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the sync parameters are written on transient storage correctly.
    if token == address0:
        with brownie.reverts('NativeTokenCannotBeSynced: '):
            tx = wrapper._writeReadReserve(token, id, reserve, multiToken)
    else:
        tx = wrapper._writeReadReserve(token, id, reserve, multiToken)

        tokenResult, \
        tokenIdResult, \
        reserveResult, \
        multiTokenResult = tx.return_value

        assert tokenResult == token
        assert reserveResult == reserve
        assert multiTokenResult == multiToken
        if multiToken:
            assert tokenIdResult == id

def test_burntPositionSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._burntPositionSlot()
    transientSlot = tx.return_value
    assert transientSlot == (keccak256('burntPosition') - 1) % (1 << 128)

@pytest.mark.parametrize('shares', [balance0, balance1, balance2, balance4, balance5, balance6, balance7, balance8])
@pytest.mark.parametrize('qMin', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qMax', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_checkBurntPosition(wrapper, shares, qMin, qMax, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if burntPosition is set correctly.
    transientSlot = keccakPacked(['uint256', 'uint64', 'uint64', 'uint128'], [poolId, qMin, qMax, (keccak256('burntPosition') - 1) % (1 << 128)])
    tx = wrapper._checkBurntPosition(poolId, qMin, qMax, shares, transientSlot)
    result = tx.return_value

    if shares > 0:
        assert result == 0
    else:
        assert result == (1 << 256) - 1

@pytest.mark.parametrize('shares', [balance1, balance2, balance4, balance5, balance6, balance7, balance8])
@pytest.mark.parametrize('qMin', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('qMax', [logPrice0, logPrice1, logPrice2, logPrice3, logPrice4])
@pytest.mark.parametrize('poolId', [value0, value1, value2, value3, value4])
def test_checkBurntPositionBurnMint(wrapper, shares, qMin, qMax, poolId, request, worker_id):
    logTest(request, worker_id)
    
    # Check if burntPosition is set correctly.
    transientSlot = keccakPacked(['uint256', 'uint64', 'uint64', 'uint128'], [poolId, qMin, qMax, (keccak256('burntPosition') - 1) % (1 << 128)])

    if shares > 0:
        with brownie.reverts('CannotMintAfterBurning: ' + str(poolId) + ', ' + str(qMin) + ', ' + str(qMax)):
            tx = wrapper._checkBurntPositionBurnMint(poolId, qMin, qMax, shares, transientSlot)
    else:
        tx = wrapper._checkBurntPositionBurnMint(poolId, qMin, qMax, shares, transientSlot)
        result = tx.return_value
        assert result == (1 << 256) - 1

def test_redeployStaticParamsAndKernelSlot(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the hash is calculated correctly.
    tx = wrapper._redeployStaticParamsAndKernelSlot()
    transientSlot = tx.return_value
    assert transientSlot == keccak256('redeployStaticParamsAndKernel') - 1

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2])
@pytest.mark.parametrize('sourcePointer', [pointer0, pointer1])
@pytest.mark.parametrize('targetPointer', [pointer0, pointer1])
@pytest.mark.parametrize('poolGrowthPortion', [portion0, portion1])
@pytest.mark.parametrize('maxPoolGrowthPortion', [portion0, portion1])
@pytest.mark.parametrize('protocolGrowthPortion', [portion0, portion1])
@pytest.mark.parametrize('pendingKernelLength', [index0, index1])
def test_redeployStaticParamsAndKernel(wrapper, poolId, sourcePointer, targetPointer, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength, request, worker_id):
    logTest(request, worker_id)
    
    # Check if redeploy parameters are set correctly.
    tx = wrapper._redeployStaticParamsAndKernel(poolId, sourcePointer, targetPointer, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength)

    poolIdResult, \
    sourcePointerResult, \
    targetPointerResult, \
    poolGrowthPortionResult, \
    maxPoolGrowthPortionResult, \
    protocolGrowthPortionResult, \
    pendingKernelLengthResult, \
    testValue = tx.return_value

    assert poolIdResult == poolId
    assert sourcePointerResult == sourcePointer
    assert targetPointerResult == targetPointer
    assert poolGrowthPortionResult == poolGrowthPortion
    assert maxPoolGrowthPortionResult == maxPoolGrowthPortion
    assert protocolGrowthPortionResult == protocolGrowthPortion
    assert pendingKernelLengthResult == pendingKernelLength
    assert testValue == True

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2])
@pytest.mark.parametrize('sourcePointer', [pointer0, pointer1])
@pytest.mark.parametrize('targetPointer', [pointer0, pointer1])
@pytest.mark.parametrize('poolGrowthPortion', [portion0, portion1])
@pytest.mark.parametrize('maxPoolGrowthPortion', [portion0, portion1])
@pytest.mark.parametrize('protocolGrowthPortion', [portion0, portion1])
@pytest.mark.parametrize('pendingKernelLength', [index0, index1])
def test_clearRedeployStaticParamsAndKernel(wrapper, poolId, sourcePointer, targetPointer, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength, request, worker_id):
    logTest(request, worker_id)
    
    # Check if redeploy parameters are cleared correctly.
    tx = wrapper._clearRedeployStaticParamsAndKernel(poolId, sourcePointer, targetPointer, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength)

    poolIdResult, \
    sourcePointerResult, \
    targetPointerResult, \
    poolGrowthPortionResult, \
    maxPoolGrowthPortionResult, \
    protocolGrowthPortionResult, \
    pendingKernelLengthResult, \
    testValue = tx.return_value

    assert poolIdResult == 0
    assert sourcePointerResult == 0
    assert targetPointerResult == 0
    assert poolGrowthPortionResult == 0
    assert maxPoolGrowthPortionResult == 0
    assert protocolGrowthPortionResult == 0
    assert pendingKernelLengthResult == 0
    assert testValue == True

def test_redeployStaticParamsAndKernelReverts(wrapper, request, worker_id):
    logTest(request, worker_id)
    
    # Check if the safegaurd for 'readRedeployStaticParamsAndKernel' works correctly.
    with brownie.reverts('CannotRedeployStaticParamsAndKernelExternally: '):
        tx = wrapper._redeployStaticParamsAndKernelReverts()