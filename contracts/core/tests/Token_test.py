# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, TokenWrapper, ERC20FixedSupply, ERC1155FixedSupply, ERC6909FixedSupply
from Nofee import logTest, address0

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    #  Two accounts are initiated
    root = accounts[0]
    other = accounts[1]

    # The total balance of the transferring contract of each token
    value = 1000000

    # The amount to be transferred
    valueToBeTransferred = 100

    # The multi-token id
    id = 5

    # Deploy the wrapper contracts
    tokenWrapper0 = TokenWrapper.deploy({'from': root})
    tokenWrapper1 = TokenWrapper.deploy({'from': root})

    # Transfer some native to the wrapper contract
    root.transfer(to = tokenWrapper0, amount = value)

    # Deploy tokens
    ERC20 = ERC20FixedSupply.deploy("", "", value, tokenWrapper0, {'from': root})
    ERC1155 = ERC1155FixedSupply.deploy("", value, id, tokenWrapper0, {'from': root})
    ERC6909 = ERC6909FixedSupply.deploy(value, id, tokenWrapper0, {'from': root})

    return root, other, value, valueToBeTransferred, id, ERC20, ERC1155, ERC6909, tokenWrapper0, tokenWrapper1

def test_native(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, other, value, valueToBeTransferred, id, ERC20, ERC1155, ERC6909, wrapper0, wrapper1 = deployment

    # We attempt to transfer '101' native tokens to 'wrapper1' which reverts
    # because the implemented 'receive()' function does not accept this exact
    # amount. The resulting revert message is then examined.
    with brownie.reverts('CannotBe101: '):
        tx = wrapper0.transfer(address0, wrapper1, 101, {'from': root})

    # The balance of 'other' before the transaction is stored
    balanceBefore = other.balance()

    # We transfer some native from 'wrapper0' to 'other'
    tx = wrapper0.transfer(address0, other, valueToBeTransferred, {'from': root})

    # The balance of 'other' is incremented by 'valueToBeTransferred'
    assert other.balance() == balanceBefore + valueToBeTransferred

    # The balance of 'wrapper0' is decremented by 'valueToBeTransferred'
    assert wrapper0.balance() == value - valueToBeTransferred

def test_erc20transfer(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, other, value, valueToBeTransferred, id, ERC20, ERC1155, ERC6909, wrapper0, wrapper1 = deployment

    # We attempt to transfer 'not(0)' ERC20 tokens to 'other' which reverts.
    # The resulting revert message is then examined.
    with brownie.reverts('ERC20InsufficientBalance: ' + wrapper0.address.lower() + ', ' + str(value) + ', ' + str((1 << 256) - 1)):
        tx = wrapper0.transfer(ERC20, other, (1 << 256) - 1, {'from': root})

    # We transfer some ERC20 from 'wrapper0' to 'other'
    tx = wrapper0.transfer(ERC20, other, valueToBeTransferred, {'from': root})

    # We store the resulting balance of 'wrapper0'
    tx = wrapper0.balanceOfSelf(ERC20, {'from': root})

    # The balance of 'other' is incremented by 'valueToBeTransferred'
    assert ERC20.balanceOf(other) == valueToBeTransferred

    # The balance of 'wrapper0' is decremented by 'valueToBeTransferred'
    assert tx.return_value == value - valueToBeTransferred

def test_erc1155transfer(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, other, value, valueToBeTransferred, id, ERC20, ERC1155, ERC6909, wrapper0, wrapper1 = deployment

    # This is the ERC1155 transfer data.
    data = b"Random"

    # We attempt to transfer 'not(0)' ERC1155 tokens to 'other' which reverts.
    # The resulting revert message is then examined.
    with brownie.reverts('ERC1155InsufficientBalance: ' + wrapper0.address.lower() + ', ' + str(value) + ', ' + str((1 << 256) - 1) + ', ' + str(id)):
        tx = wrapper0.transfer(ERC1155, id, other, (1 << 256) - 1, data, {'from': root})

    # We transfer some ERC1155 from 'wrapper0' to 'wrapper1'
    tx = wrapper0.transfer(ERC1155, id, wrapper1, valueToBeTransferred, data, {'from': root})

    # We store the resulting balance of 'wrapper0'
    tx = wrapper0.balanceOfSelf(ERC1155, id, {'from': root})

    # The balance of 'wrapper1' is incremented by 'valueToBeTransferred'
    assert ERC1155.balanceOf(wrapper1, id) == valueToBeTransferred

    # The balance of 'wrapper0' is decremented by 'valueToBeTransferred'
    assert tx.return_value == value - valueToBeTransferred

    # We check that the ERC1155 transfer data is correctly transferred.
    assert wrapper1.storedData().hex() == data.hex()

def test_erc6909transfer(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, other, value, valueToBeTransferred, id, ERC20, ERC1155, ERC6909, wrapper0, wrapper1 = deployment

    # We attempt to transfer 'not(0)' ERC6909 tokens to 'other' which reverts.
    # The resulting revert message is then examined.
    with brownie.reverts('ERC6909InsufficientBalance: ' + wrapper0.address.lower() + ', ' + str(value) + ', ' + str((1 << 256) - 1) + ', ' + str(id)):
        tx = wrapper0.transfer(ERC6909, id, other, (1 << 256) - 1, {'from': root})

    # We transfer some ERC6909 from 'wrapper0' to 'other'
    tx = wrapper0.transfer(ERC6909, id, other, valueToBeTransferred, {'from': root})

    # We store the resulting balance of 'wrapper0'
    tx = wrapper0.balanceOfSelf(ERC6909, id, {'from': root})

    # The balance of 'other' is incremented by 'valueToBeTransferred'
    assert ERC6909.balanceOf(other, id) == valueToBeTransferred

    # The balance of 'wrapper0' is decremented by 'valueToBeTransferred'
    assert tx.return_value == value - valueToBeTransferred