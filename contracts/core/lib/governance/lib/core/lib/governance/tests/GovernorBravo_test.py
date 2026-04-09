# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
import sha3
from brownie import web3, accounts, Timelock, Nofee, GovernorBravoDelegate, GovernorBravoDelegator
from eth_abi import encode

DOMAIN_TYPEHASH = sha3.keccak_256('EIP712Domain(string name,uint256 chainId,address verifyingContract)'.encode('utf-8'))
BALLOT_TYPEHASH = sha3.keccak_256('Ballot(uint256 proposalId,uint8 support)'.encode('utf-8'))
oneWeekInSeconds = 7 * 24 * 60 * 60
address0 = '0x0000000000000000000000000000000000000000'

@pytest.fixture(scope="module", autouse=True)
def deployment(module_isolation, chain):
    root_ = accounts[0]
    other0_ = accounts[1]
    other1_ = accounts[2]
    other2_ = accounts[3]
    other3_ = accounts.add()
    actor0_ = accounts[4]
    actor1_ = accounts[5]
    guy0_ = accounts[6]
    guy1_ = accounts[7]
    guy2_ = accounts[8]
    proposer0_ = accounts.add()
    proposer1_ = accounts.add()

    other2_.transfer(other3_, other2_.balance() // 2)
    guy0_.transfer(proposer0_, guy0_.balance() // 2)
    guy1_.transfer(proposer1_, guy1_.balance() // 2)

    # deploy the contracts
    timelock_ = Timelock.deploy(root_, oneWeekInSeconds, {'from': root_})
    nofeeToken = Nofee.deploy(root_, timelock_, chain[-1].timestamp + 3600, {'from': root_})
    delegate_ = GovernorBravoDelegate.deploy({'from': root_})
    delegator_ = GovernorBravoDelegator.deploy(
        timelock_, 
        nofeeToken, 
        root_, 
        delegate_, 
        5760, 
        1, 
        10000000000000000000000000, 
        {'from': root_}
    )

    # setPendingAdmin of 'timelock' to 'GovernorBravoDelegator'
    target = timelock_.address
    value = 0
    signature = 'setPendingAdmin(address)'
    data = encode(['address'], [delegator_.address])
    eta = chain[-1].timestamp + oneWeekInSeconds * 2
    timelock_.queueTransaction(target, value, signature, data, eta, {'from': root_})
    chain.sleep(oneWeekInSeconds * 3)
    timelock_.executeTransaction(target, value, signature, data, eta, {'from': root_})

    # run "_initiate(0, {'from': delegator_})"
    root_.transfer(to=delegator_, data=delegate_._initiate.encode_input(1))

    # setPendingAdmin of 'GovernorBravoDelegator' to 'timelock'
    root_.transfer(to=delegator_, data=delegate_._setPendingAdmin.encode_input(timelock_.address))

    # 'root' delegates all of its tokens to 'address0'
    with brownie.reverts("Nofee::_delegate: cannot delegate to the zero address"):
        nofeeToken.delegate(address0, {'from': root_})

    # 'root' delegates all of its tokens to 'root'
    nofeeToken.delegate(root_, {'from': root_})
    chain.mine(10)

    # 'timelock' accepts admin
    targets = [delegator_.address]
    values = [0]
    signatures = ['_acceptAdmin()']
    calldatas = [b'']
    description = ''
    root_.transfer(to=delegator_, data=delegate_.propose.encode_input(targets, values, signatures, calldatas, description))
    chain.mine(10)
    root_.transfer(to=delegator_, data=delegate_.castVote.encode_input(2, 1))
    chain.mine(5760)
    root_.transfer(to=delegator_, data=delegate_.queue.encode_input(2))
    chain.mine(20)
    chain.sleep(oneWeekInSeconds * 1)
    root_.transfer(to=delegator_, data=delegate_.execute.encode_input(2))

    # do nothing proposal
    targets = [other0_.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0_.address])]
    description = 'do nothing'
    tx = root_.transfer(to=delegator_, data=delegate_.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId_ = tx.events['ProposalCreated']['id']

    return timelock_, nofeeToken, delegate_, delegator_, proposalId_, root_, \
        other0_, other1_, other2_, other3_, \
        actor0_, actor1_, \
        guy0_, guy1_, guy2_, \
        proposer0_, proposer1_

def test_constructor(deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment

    assert timelock.admin() == delegator.address
    assert timelock.pendingAdmin() == '0x0000000000000000000000000000000000000000'

    assert delegator.admin() == timelock.address
    assert delegator.pendingAdmin() == '0x0000000000000000000000000000000000000000'
    assert delegator.implementation() == delegate.address

    assert nofeeToken.minter() == timelock.address    

def test_revert(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment

    # We must revert if there does not exist a proposal with matching proposal id where the current 
    # block number is between the proposal's start block (exclusive) and end block (inclusive)
    with brownie.reverts('GovernorBravo::castVoteInternal: voting is closed'):
        root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))

    # We must revert such proposal already has an entry in its voters set matching the sender
    chain.mine(2)

    other0.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))
    other1.transfer(to=delegator, data=delegate.castVoteWithReason.encode_input(proposalId, 1, ''))
    with brownie.reverts('GovernorBravo::castVoteInternal: voter already voted'):
        other0.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))

def test_success(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment

    # We add other2 to the proposal's voters set
    tx = root.transfer(to=delegator, data=delegate.getReceipt.encode_input(proposalId, other2.address))
    assert tx.subcalls[0]['return_value'][0][0] == False

    other2.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))

    tx = root.transfer(to=delegator, data=delegate.getReceipt.encode_input(proposalId, other2.address))
    assert tx.subcalls[0]['return_value'][0][0] == True

    # we take the balance returned by GetPriorVotes for the given sender 
    # and the proposal's start block, which may be zero
    nofeeToken.transfer(other1, 10000000000000000000000001, {'from': root})
    nofeeToken.delegate(other1, {'from': other1})
    chain.mine(10)

    targets = [other0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0.address])]
    description = 'do nothing'
    tx = other1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId = tx.events['ProposalCreated']['id']

    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    beforeFors = tx.subcalls[0]['return_value'][5]
    chain.mine(1)
    other1.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))

    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    afterFors = tx.subcalls[0]['return_value'][5]

    assert afterFors == beforeFors + 10000000000000000000000001

    # This time we count the against votes
    nofeeToken.transfer(other2, 10000000000000000000000001, {'from': root})
    nofeeToken.delegate(other2, {'from': other2})
    chain.mine(10)

    targets = [other0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0.address])]
    description = 'do nothing'
    tx = other2.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId = tx.events['ProposalCreated']['id']

    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    beforeAgainsts = tx.subcalls[0]['return_value'][6]
    chain.mine(1)
    other2.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 0))

    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    afterAgainsts = tx.subcalls[0]['return_value'][6]

    assert afterAgainsts == beforeAgainsts + 10000000000000000000000001

def test_castVoteBySig(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment
    
    # Revert with invalid signatory
    with brownie.reverts('GovernorBravo::castVoteBySig: invalid signature'):
        root.transfer(to=delegator, data=delegate.castVoteBySig.encode_input(proposalId, 0, 0, '0xbad', '0xbad'))

    # do nothing proposal
    nofeeToken.transfer(other3, 10000000000000000000000001, {'from': root})
    nofeeToken.delegate(other3, {'from': other3})
    chain.mine(10)

    targets = [other0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0.address])]
    description = 'do nothing'
    tx = other3.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId = tx.events['ProposalCreated']['id']

    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    beforeFors = tx.subcalls[0]['return_value'][5]
    chain.mine(1)

    # casts vote on behalf of the signatory
    domainSeparator = sha3.keccak_256(encode(
        ['bytes32', 'bytes32', 'uint256', 'address'],
        [
            DOMAIN_TYPEHASH.digest(), 
            sha3.keccak_256('Nofeeswap Governor Bravo'.encode('utf-8')).digest(), 
            brownie.chain.id, 
            delegator.address
        ]
    ))
    structHash = sha3.keccak_256(encode(
        ['bytes32', 'uint256', 'uint8'],
        [BALLOT_TYPEHASH.digest(), proposalId, 1]
    ))
    digest = sha3.keccak_256((b'\x19\x01') + domainSeparator.digest() + structHash.digest())
    signed = web3.eth.account.signHash(digest.hexdigest(), other3.private_key)
    r = brownie.convert.to_bytes(signed.r, type_str='bytes32')
    s = brownie.convert.to_bytes(signed.s, type_str='bytes32')
    v = signed.v

    tx = root.transfer(to=delegator, data=delegate.castVoteBySig.encode_input(proposalId, 1, v, r, s))
    assert tx.gas_used < 120000

    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    afterFors = tx.subcalls[0]['return_value'][5]
    assert afterFors == beforeFors + 10000000000000000000000001

def test_receipt(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment
    
    nofeeToken.transfer(actor0, 10000000000000000000000001, {'from': root})
    nofeeToken.transfer(actor1, 10000000000000000000000001, {'from': root})
    nofeeToken.delegate(actor0, {'from': actor0})
    nofeeToken.delegate(actor1, {'from': actor1})
    chain.mine(10)

    # do nothing proposal
    targets = [other0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0.address])]
    description = 'do nothing'
    tx = actor0.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId = tx.events['ProposalCreated']['id']

    chain.mine(2)
    actor0.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))
    actor1.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 0))

    tx = root.transfer(to=delegator, data=delegate.getReceipt.encode_input(proposalId, actor0.address))
    txReceipt0 = tx.subcalls[0]['return_value'][0]
    tx = root.transfer(to=delegator, data=delegate.getReceipt.encode_input(proposalId, actor1.address))
    txReceipt1 = tx.subcalls[0]['return_value'][0]

    assert txReceipt0[0]
    assert txReceipt1[0]
    assert txReceipt0[1] == 1
    assert txReceipt1[1] == 0
    assert txReceipt0[2] == 10000000000000000000000001
    assert txReceipt1[2] == 10000000000000000000000001

def test_propose(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment
    
    # do nothing proposal
    targets = [other0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0.address])]
    description = 'do nothing'
    tx = root.transfer(to=delegator, data=delegate.proposalCount.encode_input())
    proposalId = tx.subcalls[0]['return_value'][0] + 1
    tx = actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalBlock = chain[-1]['number']
    proposalEvent = tx.events['ProposalCreated']

    # Additionally, if there exists a pending or active proposal from the same proposer, we must revert.
    with brownie.reverts('GovernorBravo::propose: one live proposal per proposer, found an already pending proposal'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))

    chain.mine(2)

    with brownie.reverts('GovernorBravo::propose: one live proposal per proposer, found an already active proposal'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))

    # correct event
    assert proposalEvent['id'] == proposalId
    assert proposalEvent['targets'] == targets
    assert proposalEvent['values'] == values
    assert proposalEvent['signatures'] == signatures
    assert brownie.convert.to_bytes(proposalEvent['calldatas'][0], type_str='bytes32') == calldatas[0]
    assert proposalEvent['startBlock'] == proposalBlock + 1
    assert proposalEvent['endBlock'] == proposalBlock + 1 + 5760
    assert proposalEvent['description'] == 'do nothing'
    assert proposalEvent['proposer'] == actor1.address

    # correct initialization
    tx = root.transfer(to=delegator, data=delegate.proposals.encode_input(proposalId))
    proposal = tx.subcalls[0]['return_value']

    assert proposal[0] == proposalId
    assert proposal[1] == actor1.address
    assert proposal[2] == 0
    assert proposal[3] == proposalBlock + 1
    assert proposal[4] == proposalBlock + 1 + 5760
    assert proposal[5] == 0
    assert proposal[6] == 0
    assert proposal[7] == 0
    assert not(proposal[8])
    assert not(proposal[9])

    # Targets, Values, Signatures, Calldatas are set according to parameters
    tx = root.transfer(to=delegator, data=delegate.getActions.encode_input(proposalId))
    dynamicFields = tx.subcalls[0]['return_value']

    assert dynamicFields[0] == targets
    assert dynamicFields[1] == values
    assert dynamicFields[2] == signatures
    assert brownie.convert.to_bytes(dynamicFields[3][0], type_str='bytes32') == calldatas[0]

    # This function must revert the length of the values, signatures or calldatas arrays are not the same length
    with brownie.reverts('GovernorBravo::propose: proposal function information arity mismatch'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets + targets, values, signatures, calldatas, description))

    with brownie.reverts('GovernorBravo::propose: proposal function information arity mismatch'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values + values, signatures, calldatas, description))

    with brownie.reverts('GovernorBravo::propose: proposal function information arity mismatch'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures + signatures, calldatas, description))

    with brownie.reverts('GovernorBravo::propose: proposal function information arity mismatch'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas + calldatas, description))

    # This function must revert the length is zero or above the max operations
    with brownie.reverts('GovernorBravo::propose: must provide actions'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input([], [], [], [], description))

    with brownie.reverts('GovernorBravo::propose: too many actions'):
        actor1.transfer(to=delegator, data=delegate.propose.encode_input(targets*11, values*11, signatures*11, calldatas*11, description))

def test_queue(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment
    
    nofeeToken.transfer(guy0, 10000000000000000000000001, {'from': root})
    nofeeToken.transfer(guy1, 10000000000000000000000001, {'from': root})
    nofeeToken.transfer(guy2, 10000000000000000000000001, {'from': root})
    nofeeToken.delegate(guy0, {'from': guy0})
    nofeeToken.delegate(guy1, {'from': guy1})
    nofeeToken.delegate(guy2, {'from': guy2})
    chain.mine(1)

    # do nothing proposal with overlapping actions
    targets = [other0.address]*2
    values = [0]*2
    signatures = ['getBalanceOf(address)']*2
    calldatas = [encode(['address'], [other0.address])]*2
    description = 'do nothing with overlapping actions'
    tx = guy0.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId = tx.events['ProposalCreated']['id']
    chain.mine(1)

    # cast vote
    root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId, 1))
    chain.mine(5760)

    # reverts on queueing overlapping actions in same proposal
    with brownie.reverts('GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta'):
        guy0.transfer(to=delegator, data=delegate.queue.encode_input(proposalId))

    # now we create two 'do nothing' proposals with overlapping actions
    targets = [other0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    calldatas = [encode(['address'], [other0.address])]
    description = 'do nothing'
    tx = guy1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId1 = tx.events['ProposalCreated']['id']
    chain.mine(1)
    tx = guy2.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId2 = tx.events['ProposalCreated']['id']
    chain.mine(1)

    # cast vote
    root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId1, 1))
    root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId2, 1))
    chain.mine(5760)

    # reverts on queueing overlapping actions in different proposals, works if waiting
    guy1.transfer(to=delegator, data=delegate.queue.encode_input(proposalId1))
    # with brownie.reverts('GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta'):
    #     guy2.transfer(to=delegator, data=delegate.queue.encode_input(proposalId2))

def test_state(chain, deployment, request, worker_id):
    timelock, nofeeToken, delegate, delegator, proposalId, root, \
    other0, other1, other2, other3, \
    actor0, actor1, \
    guy0, guy1, guy2, \
    proposer0, proposer1 = deployment
    
    nofeeToken.transfer(proposer0, 10000000000000000000000001, {'from': root})
    nofeeToken.transfer(proposer1, 10000000000000000000000001, {'from': root})
    nofeeToken.delegate(proposer0, {'from': proposer0})
    nofeeToken.delegate(proposer1, {'from': proposer1})
    chain.mine(1)

    # create a 'do nothing' proposals
    targets = [proposer0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    description = 'do nothing'
    calldatas = [encode(['address'], [proposer0.address])]
    tx = proposer0.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId0 = tx.events['ProposalCreated']['id']

    # Pending
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 0

    # Active
    chain.mine(2)
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 1

    # Invalid for proposal not found
    with brownie.reverts('GovernorBravo::state: invalid proposal id'):
        root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0 + 1))

    # Succeeded
    chain.mine(1)
    root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId0, 1))
    chain.mine(5760)
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 4

    # Canceled
    with brownie.reverts('Timelock::cancelTransaction: Nonexistent transaction.'):
        proposer0.transfer(to=delegator, data=delegate.cancel.encode_input(proposalId0))

    # Queued
    proposer0.transfer(to=delegator, data=delegate.queue.encode_input(proposalId0))
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 5

    # Canceled
    proposer0.transfer(to=delegator, data=delegate.cancel.encode_input(proposalId0))
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 2

    # create a 'do nothing' proposals
    targets = [guy0.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    description = 'do nothing'
    calldatas = [encode(['address'], [guy0.address])]
    tx = proposer0.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId0 = tx.events['ProposalCreated']['id']

    # Defeated
    chain.mine(5760)
    chain.mine(10)
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 3

    # create a 'do nothing' proposals
    targets = [guy1.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    description = 'do nothing'
    calldatas = [encode(['address'], [guy1.address])]
    tx = proposer0.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId0 = tx.events['ProposalCreated']['id']

    # Succeeded
    chain.mine(1)
    root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId0, 1))
    chain.mine(5760)
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 4

    # Queued
    proposer0.transfer(to=delegator, data=delegate.queue.encode_input(proposalId0))
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 5

    # Executed
    chain.sleep(oneWeekInSeconds * 1)
    proposer0.transfer(to=delegator, data=delegate.execute.encode_input(proposalId0))
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 7
    chain.sleep(oneWeekInSeconds * 1)
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId0))
    assert tx.subcalls[0]['return_value'][0] == 7

    # create a 'do nothing' proposals
    targets = [guy2.address]
    values = [0]
    signatures = ['getBalanceOf(address)']
    description = 'do nothing'
    calldatas = [encode(['address'], [guy2.address])]
    tx = proposer1.transfer(to=delegator, data=delegate.propose.encode_input(targets, values, signatures, calldatas, description))
    proposalId1 = tx.events['ProposalCreated']['id']

    # Expired
    chain.mine(1)
    root.transfer(to=delegator, data=delegate.castVote.encode_input(proposalId1, 1))
    chain.mine(5760)
    proposer1.transfer(to=delegator, data=delegate.queue.encode_input(proposalId1))
    chain.sleep(oneWeekInSeconds * 100)
    tx = root.transfer(to=delegator, data=delegate.state.encode_input(proposalId1))
    assert tx.subcalls[0]['return_value'][0] == 6