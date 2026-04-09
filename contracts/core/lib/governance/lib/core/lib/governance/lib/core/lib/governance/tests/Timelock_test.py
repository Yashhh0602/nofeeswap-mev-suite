# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
import sha3
from brownie import accounts, chain, Timelock
from eth_abi import encode

oneWeekInSeconds = 7 * 24 * 60 * 60
gracePeriod = 2 * oneWeekInSeconds

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    # Three accounts are initiated.
    admin = accounts[0]
    notAdmin = accounts[1]
    newAdmin = accounts[2]

    # Initial Timelock delay is chosen.
    initialDelay = oneWeekInSeconds // 2

    # Timelock delay is chosen.
    delay = oneWeekInSeconds

    # Timelock is deployed.
    timelock = Timelock.deploy(admin, initialDelay, {'from': admin})

    return admin, notAdmin, newAdmin, initialDelay, delay, timelock

def test_constructor(deployment, request, worker_id):
    admin, notAdmin, newAdmin, initialDelay, delay, timelock = deployment

    # We check that the admin is set correctly.
    assert timelock.admin() == admin

    # We check that the delay is set correctly.
    assert timelock.delay() == initialDelay

def test_setDelay(deployment, request, worker_id):
    admin, notAdmin, newAdmin, initialDelay, delay, timelock = deployment

    # Attempting to set delay via an account other than Timelock which reverts.
    with brownie.reverts('Timelock::setDelay: Call must come from Timelock.'):
        timelock.setDelay(delay, {'from': admin})

    # Setting a transaction with eta less than the current delay.
    target = timelock.address
    value = 0
    signature = 'setDelay(uint256)'
    data = encode(['uint256'], [delay])
    eta = chain[-1].timestamp + initialDelay - 1
    queuedTxHash = sha3.keccak_256(
        encode(
            ['address', 'uint256', 'string', 'bytes', 'uint256'],
            [target, value, signature, brownie.convert.to_bytes(data, type_str='bytes'), eta]
        )
    ).hexdigest()

    # Attempting to queue the transaction which reverts.
    with brownie.reverts('Timelock::queueTransaction: Estimated execution block must satisfy delay.'):
        timelock.queueTransaction(target, value, signature, data, eta, {'from': admin})

    # Attempting to set delay to a value lower than 'MINIMUM_DELAY' which reverts.
    target = timelock.address
    value = 0
    signature = 'setDelay(uint256)'
    data = encode(['uint256'], [timelock.MINIMUM_DELAY() - 1])
    eta = chain[-1].timestamp + 2 * delay
    queuedTxHash = sha3.keccak_256(
        encode(
            ['address', 'uint256', 'string', 'bytes', 'uint256'],
            [target, value, signature, brownie.convert.to_bytes(data, type_str='bytes'), eta]
        )
    ).hexdigest()
    
    # 'queuedTransactions' must be false prior to queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == False

    # Attempting to queue the transaction via an account other than the admin which reverts.
    with brownie.reverts('Timelock::queueTransaction: Call must come from admin.'):
        tx = timelock.queueTransaction(target, value, signature, data, eta, {'from': notAdmin})

    # Queuing the transaction.
    tx = timelock.queueTransaction(target, value, signature, data, eta, {'from': admin})
    
    # Checking the return data.
    assert str(tx.return_value)[2:] == queuedTxHash
    
    # 'queuedTransactions' must be true after queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == True
    
    # Checking that the 'QueueTransaction' event is emitted correctly.
    assert str(tx.events['QueueTransaction']['txHash']) == '0x' + queuedTxHash
    assert tx.events['QueueTransaction']['target'] == target
    assert tx.events['QueueTransaction']['value'] == value
    assert tx.events['QueueTransaction']['signature'] == signature
    assert brownie.convert.to_bytes(tx.events['QueueTransaction']['data'], type_str='bytes') == data
    assert tx.events['QueueTransaction']['eta'] == eta
    
    # Proceed forward until eta is met.
    chain.sleep(3 * delay)

    # Attempting to execute which reverts.
    with brownie.reverts('Timelock::executeTransaction: Transaction execution reverted.'):
        tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})

    # Attempting to cancel the transaction with an account other than admin which reverts.
    with brownie.reverts('Timelock::cancelTransaction: Call must come from admin.'):
        timelock.cancelTransaction(target, value, signature, data, eta, {'from': notAdmin})

    # Cancel the transaction.
    tx = timelock.cancelTransaction(target, value, signature, data, eta, {'from': admin})

    # 'queuedTransactions' must be false after canceling the transaction
    assert timelock.queuedTransactions(queuedTxHash) == False

    # Checking that the 'CancelTransaction' event is emitted correctly.
    assert str(tx.events['CancelTransaction']['txHash']) == '0x' + queuedTxHash
    assert tx.events['CancelTransaction']['target'] == target
    assert tx.events['CancelTransaction']['value'] == value
    assert tx.events['CancelTransaction']['signature'] == signature
    assert brownie.convert.to_bytes(tx.events['CancelTransaction']['data'], type_str='bytes') == data
    assert tx.events['CancelTransaction']['eta'] == eta

    # Set the parameters for a transaction that would set delay to a value higher
    # than 'MAXIMUM_DELAY' which reverts.
    target = timelock.address
    value = 0
    signature = 'setDelay(uint256)'
    data = encode(['uint256'], [timelock.MAXIMUM_DELAY() + 1])
    eta = chain[-1].timestamp + 2 * delay
    queuedTxHash = sha3.keccak_256(
        encode(
            ['address', 'uint256', 'string', 'bytes', 'uint256'],
            [target, value, signature, brownie.convert.to_bytes(data, type_str='bytes'), eta]
        )
    ).hexdigest()
    
    # 'queuedTransactions' must be false prior to queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == False

    # Queuing the transaction.
    tx = timelock.queueTransaction(target, value, signature, data, eta, {'from': admin})
    
    # Checking the return data.
    assert str(tx.return_value)[2:] == queuedTxHash
    
    # 'queuedTransactions' must be true after queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == True
    
    # Checking that the 'QueueTransaction' event is emitted correctly.
    assert str(tx.events['QueueTransaction']['txHash']) == '0x' + queuedTxHash
    assert tx.events['QueueTransaction']['target'] == target
    assert tx.events['QueueTransaction']['value'] == value
    assert tx.events['QueueTransaction']['signature'] == signature
    assert brownie.convert.to_bytes(tx.events['QueueTransaction']['data'], type_str='bytes') == data
    assert tx.events['QueueTransaction']['eta'] == eta
    
    # Proceed forward until eta is met.
    chain.sleep(3 * delay)

    # Attempting to execute which reverts.
    with brownie.reverts('Timelock::executeTransaction: Transaction execution reverted.'):
        tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})

    # Set the parameters for a transaction that would set delay to a valid value.
    target = timelock.address
    value = 0
    signature = 'setDelay(uint256)'
    data = encode(['uint256'], [delay])
    eta = chain[-1].timestamp + 2 * delay
    queuedTxHash = sha3.keccak_256(
        encode(
            ['address', 'uint256', 'string', 'bytes', 'uint256'],
            [target, value, signature, brownie.convert.to_bytes(data, type_str='bytes'), eta]
        )
    ).hexdigest()

    # Attempting to execute the transaction via an account other than the admin which reverts.
    with brownie.reverts('Timelock::executeTransaction: Call must come from admin.'):
        tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': notAdmin})

    # Attempting to execute the transaction before queuing which reverts.
    with brownie.reverts('Timelock::executeTransaction: Transaction hasn\'t been queued.'):
        tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})
    
    # 'queuedTransactions' must be false prior to queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == False

    # Queuing the transaction.
    tx = timelock.queueTransaction(target, value, signature, data, eta, {'from': admin})
    
    # Checking the return data.
    assert str(tx.return_value)[2:] == queuedTxHash
    
    # 'queuedTransactions' must be true after queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == True
    
    # Checking that the 'QueueTransaction' event is emitted correctly.
    assert str(tx.events['QueueTransaction']['txHash']) == '0x' + queuedTxHash
    assert tx.events['QueueTransaction']['target'] == target
    assert tx.events['QueueTransaction']['value'] == value
    assert tx.events['QueueTransaction']['signature'] == signature
    assert brownie.convert.to_bytes(tx.events['QueueTransaction']['data'], type_str='bytes') == data
    assert tx.events['QueueTransaction']['eta'] == eta
    
    # Attempting to execute the transaction before eta which reverts.
    with brownie.reverts('Timelock::executeTransaction: Transaction hasn\'t surpassed time lock.'):
        tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})

    # Proceed forward until 'eta + gracePeriod' is past.
    chain.sleep(4 * delay)

    # Attempting to execute a stale transaction which reverts.
    with brownie.reverts('Timelock::executeTransaction: Transaction is stale.'):
        tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})

    # Set the parameters again.
    target = timelock.address
    value = 0
    signature = 'setDelay(uint256)'
    data = encode(['uint256'], [delay])
    eta = chain[-1].timestamp + 2 * delay
    queuedTxHash = sha3.keccak_256(
        encode(
            ['address', 'uint256', 'string', 'bytes', 'uint256'],
            [target, value, signature, brownie.convert.to_bytes(data, type_str='bytes'), eta]
        )
    ).hexdigest()

    # 'queuedTransactions' must be false prior to queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == False

    # Queuing the transaction.
    tx = timelock.queueTransaction(target, value, signature, data, eta, {'from': admin})

    # Checking the return data.
    assert str(tx.return_value)[2:] == queuedTxHash
    
    # 'queuedTransactions' must be true after queuing the transaction.
    assert timelock.queuedTransactions(queuedTxHash) == True

    # Checking that the 'QueueTransaction' event is emitted correctly.
    assert str(tx.events['QueueTransaction']['txHash']) == '0x' + queuedTxHash
    assert tx.events['QueueTransaction']['target'] == target
    assert tx.events['QueueTransaction']['value'] == value
    assert tx.events['QueueTransaction']['signature'] == signature
    assert brownie.convert.to_bytes(tx.events['QueueTransaction']['data'], type_str='bytes') == data
    assert tx.events['QueueTransaction']['eta'] == eta

    # Proceed forward until eta is met.
    chain.sleep(3 * delay)

    # Successfully execute.
    tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})

    # 'queuedTransactions' must be false after execution.
    assert timelock.queuedTransactions(queuedTxHash) == False

    # We check that the delay is set correctly.
    assert timelock.delay() == delay

    # We check that the delay event is emitted correctly.
    assert tx.events['NewDelay']['newDelay'] == delay

    # Checking that the 'ExecuteTransaction' event is emitted correctly.
    assert str(tx.events['ExecuteTransaction']['txHash']) == '0x' + queuedTxHash
    assert tx.events['ExecuteTransaction']['target'] == target
    assert tx.events['ExecuteTransaction']['value'] == value
    assert tx.events['ExecuteTransaction']['signature'] == signature
    assert brownie.convert.to_bytes(tx.events['ExecuteTransaction']['data'], type_str='bytes') == data
    assert tx.events['ExecuteTransaction']['eta'] == eta

def test_admin(deployment, request, worker_id):
    admin, notAdmin, newAdmin, initialDelay, delay, timelock = deployment

    # Attempting to set admin via an account other than Timelock which reverts.
    with brownie.reverts('Timelock::setPendingAdmin: Call must come from Timelock.'):
        timelock.setPendingAdmin(notAdmin, {'from': admin})
    
    # Setting admin successfully to 'admin0'.
    target = timelock.address
    value = 0
    signature = 'setPendingAdmin(address)'
    data = encode(['address'], [newAdmin.address])
    eta = chain[-1].timestamp + 2 * delay
    txHash = timelock.queueTransaction(target, value, signature, data, eta, {'from': admin})
    chain.sleep(3 * delay)
    tx = timelock.executeTransaction(target, value, signature, data, eta, {'from': admin})

    # Checking the resulting transaction hash.
    assert str(txHash.return_value)[2:] == sha3.keccak_256(
        encode(
            ['address', 'uint256', 'string', 'bytes', 'uint256'],
            [target, value, signature, brownie.convert.to_bytes(data, type_str='bytes'), eta]
        )
    ).hexdigest()

    # Checking that the pending admin is set correctly.
    assert timelock.pendingAdmin() == newAdmin.address

    # We check that the pending admin event is emitted correctly.
    assert tx.events['NewPendingAdmin']['newPendingAdmin'] == newAdmin.address

    # Attempting to accept admin via an account other than the pending admin which revert.
    with brownie.reverts('Timelock::acceptAdmin: Call must come from pendingAdmin.'):
        timelock.acceptAdmin({'from': admin})

    # Pending admin accepts.
    tx = timelock.acceptAdmin({'from': newAdmin})

    # Checking that the new admin is set correctly.
    assert timelock.admin() == newAdmin.address

    # We check that the new admin event is emitted correctly.
    assert tx.events['NewAdmin']['newAdmin'] == newAdmin.address