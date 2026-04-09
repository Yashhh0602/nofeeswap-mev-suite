# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Nofeeswap, ERC20FixedSupply, Operator
from eth_abi import encode
from eth_abi.packed import encode_packed
from Nofee import logTest, ISZERO, JUMP, JUMPDEST, REVERT, PUSH32, NEG, TRANSFER_FROM_PAYER_ERC20, TAKE_TOKEN, SYNC_TOKEN, SETTLE, MODIFY_SINGLE_BALANCE, MODIFY_DOUBLE_BALANCE, toInt, address0

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    nofeeswap = Nofeeswap.deploy(address0, owner.address, {'from': owner})
    operator = Operator.deploy(nofeeswap, address0, address0, address0, {'from': root})

    return root, owner, nofeeswap, operator

def test_modifySingleBalance(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, nofeeswap, operator = deployment

    token = ERC20FixedSupply.deploy("ERC20", "ERC20", 2**120, owner, {'from': owner})
    assert token.balanceOf(nofeeswap) == 0
    token.approve(operator, 10, {'from': owner})
    tag = toInt(token.address)
    
    # Owner mints 10 tokens
    amountSlot = 4
    successSlot = 6

    successSlotSync = 8

    successSlotTransfer = 11
    resultSlotTransfer = 15

    valueSlotSettle = 25
    successSlotSettle = 27
    resultSlotSettle = 99

    amount = 2 ** 128

    deadline = 2 ** 32 - 1

    ###############################

    sequence = [0] * 5
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount, amountSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag, amountSlot, successSlot]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[3] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:4]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('BalanceOverflow: ' + str(amount)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    amount = 10

    sequence = [0] * 5
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount, amountSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag, amountSlot, successSlot]
    )
    sequence[2] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token.address]
    )
    sequence[3] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token.address, amountSlot, nofeeswap.address, successSlotTransfer, resultSlotTransfer]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle, successSlotSettle, resultSlotSettle]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)    
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    assert token.balanceOf(nofeeswap) == 10
    assert nofeeswap.balanceOf(owner, tag) == 10
    assert tx.events['Transfer']['caller'] == operator
    assert tx.events['Transfer']['from'] == address0
    assert tx.events['Transfer']['to'] == owner
    assert tx.events['Transfer']['tag'] == tag
    assert tx.events['Transfer']['amount'] == 10

    ###############################

    amount = -10

    # Owner approves 10 tokens to 'modifySingleBalance'
    tx = nofeeswap.approve(operator, tag, 5, {'from': owner})

    assert nofeeswap.allowance(owner, operator, tag) == 5
    assert tx.events['Approval']['owner'] == owner
    assert tx.events['Approval']['spender'] == operator
    assert tx.events['Approval']['tag'] == tag
    assert tx.events['Approval']['amount'] == 5

    sequence = [0] * 5
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount, amountSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag, amountSlot, successSlot]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[3] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:4]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('InsufficientPermission: ' + str(operator.address.lower()) + ', ' + str(tag)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    # Owner approves 10 tokens to 'modifySingleBalance'
    tx = nofeeswap.approve(operator, tag, 100, {'from': owner})

    assert nofeeswap.allowance(owner, operator, tag) == 100
    assert tx.events['Approval']['owner'] == owner
    assert tx.events['Approval']['spender'] == operator
    assert tx.events['Approval']['tag'] == tag
    assert tx.events['Approval']['amount'] == 100

    ###############################

    amount = -100

    sequence = [0] * 5
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount, amountSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag, amountSlot, successSlot]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[3] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:4]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('InsufficientBalance: ' + owner.address.lower() + ', ' + str(tag)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    amount = -10

    # Owner burns 10 tokens
    sequence = [0] * 4
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount, amountSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag, amountSlot, successSlot]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amountSlot, amountSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token.address, owner.address, amountSlot, successSlotSettle]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    assert token.balanceOf(nofeeswap) == 0
    assert nofeeswap.balanceOf(owner, tag) == 0
    assert nofeeswap.allowance(owner, operator, tag) == 90
    assert tx.events['Transfer']['caller'] == operator
    assert tx.events['Transfer']['from'] == owner
    assert tx.events['Transfer']['to'] == address0
    assert tx.events['Transfer']['tag'] == tag
    assert tx.events['Transfer']['amount'] == 10

def test_modifyDoubleBalance(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, nofeeswap, operator = deployment

    token0 = ERC20FixedSupply.deploy("ERC20", "ERC20", 20, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20", "ERC20", 20, owner, {'from': owner})
    assert token0.balanceOf(nofeeswap) == 0
    assert token1.balanceOf(nofeeswap) == 0
    token0.approve(operator, 20, {'from': owner})
    token1.approve(operator, 20, {'from': owner})
    tag0 = min(toInt(token0.address), toInt(token1.address))
    tag1 = max(toInt(token0.address), toInt(token1.address))

    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    
    # Owner mints (10, 20) tokens
    sequence = [0] * 3
    deadline = 2 ** 32 - 1

    successSlot = 6

    amountSlot0 = 4
    amountSlot1 = 5

    successSlotTransfer0 = 11
    successSlotTransfer1 = 16

    valueSlotSettle0 = 25
    successSlotSettle0 = 27
    resultSlotSettle0 = 99

    valueSlotSettle1 = 125
    successSlotSettle1 = 127
    resultSlotSettle1 = 199

    ###############################

    amount0 = 2 ** 128
    amount1 = 20

    sequence = [0] * 6
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[5] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:5]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('BalanceOverflow: ' + str(amount0)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    amount0 = 10
    amount1 = 2 ** 128

    sequence = [0] * 6
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[5] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:5]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('BalanceOverflow: ' + str(amount1)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    amount0 = 10
    amount1 = 20

    sequence = [0] * 9
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token0.address]
    )
    sequence[4] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token0.address, amountSlot0, nofeeswap.address, successSlotTransfer0, 0]
    )
    sequence[5] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle0, successSlotSettle0, resultSlotSettle0]
    )
    sequence[6] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token1.address]
    )
    sequence[7] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token1.address, amountSlot1, nofeeswap.address, successSlotTransfer1, 0]
    )
    sequence[8] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle1, successSlotSettle1, resultSlotSettle1]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    assert token0.balanceOf(nofeeswap) == 10
    assert token1.balanceOf(nofeeswap) == 20

    assert tx.events['ModifyDoubleBalanceEvent'][0]['caller'] == operator.address
    assert tx.events['ModifyDoubleBalanceEvent'][0]['owner'] == owner.address
    assert tx.events['ModifyDoubleBalanceEvent'][0]['increment'] == 10
    assert tx.events['ModifyDoubleBalanceEvent'][0]['balance'] == 10

    assert tx.events['ModifyDoubleBalanceEvent'][1]['caller'] == operator.address
    assert tx.events['ModifyDoubleBalanceEvent'][1]['owner'] == owner.address
    assert tx.events['ModifyDoubleBalanceEvent'][1]['increment'] == 20
    assert tx.events['ModifyDoubleBalanceEvent'][1]['balance'] == 20

    ###############################

    tx = nofeeswap.approve(operator, tag0, 5, {'from': owner})
    tx = nofeeswap.approve(operator, tag1, 5, {'from': owner})

    amount0 = -10
    amount1 = -10

    sequence = [0] * 6
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, 0, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[5] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:5]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('InsufficientPermission: ' + str(operator.address.lower()) + ', ' + str(tag0)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    sequence = [0] * 6
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, 0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[5] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:5]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('InsufficientPermission: ' + str(operator.address.lower()) + ', ' + str(tag1)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    # Owner approves (10, 20) tokens to 'operator'
    tx = nofeeswap.approve(operator, tag0, 100, {'from': owner})
    tx = nofeeswap.approve(operator, tag1, 110, {'from': owner})

    amount0 = -100
    amount1 = 20

    sequence = [0] * 6
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[5] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:5]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('InsufficientBalance: ' + owner.address.lower() + ', ' + str(tag0)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    amount0 = -10
    amount1 = -110

    sequence = [0] * 6
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[5] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:5]]), successSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

    with brownie.reverts('InsufficientBalance: ' + owner.address.lower() + ', ' + str(tag1)):
        tx = nofeeswap.unlock(operator, data, {'from': owner})

    ###############################

    amount0 = -10
    amount1 = -20

    # Owner burns (10, 20) tokens
    deadline = 2 ** 32 - 1

    sequence = [0] * 7
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amountSlot0]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amountSlot1]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint256', 'uint8', 'uint8', 'uint8'],
      [MODIFY_DOUBLE_BALANCE, tag0, tag1, amountSlot0, amountSlot1, successSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amountSlot0, amountSlot0]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amountSlot1, amountSlot1]
    )
    sequence[5] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token0.address, owner.address, amountSlot0, successSlotSettle0]
    )
    sequence[6] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token1.address, owner.address, amountSlot1, successSlotSettle1]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    assert token0.balanceOf(nofeeswap) == 0
    assert token1.balanceOf(nofeeswap) == 0
    
    assert nofeeswap.balanceOf(owner, tag0) == 0
    assert nofeeswap.balanceOf(owner, tag1) == 0

    assert nofeeswap.allowance(owner, operator, tag0) == 90
    assert nofeeswap.allowance(owner, operator, tag1) == 90

    assert tx.events['ModifyDoubleBalanceEvent'][0]['caller'] == operator.address
    assert tx.events['ModifyDoubleBalanceEvent'][0]['owner'] == owner.address
    assert tx.events['ModifyDoubleBalanceEvent'][0]['increment'] == -10
    assert tx.events['ModifyDoubleBalanceEvent'][0]['balance'] == 0

    assert tx.events['ModifyDoubleBalanceEvent'][1]['caller'] == operator.address
    assert tx.events['ModifyDoubleBalanceEvent'][1]['owner'] == owner.address
    assert tx.events['ModifyDoubleBalanceEvent'][1]['increment'] == -20
    assert tx.events['ModifyDoubleBalanceEvent'][1]['balance'] == 0