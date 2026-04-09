# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import chain, accounts, Nofee, NofeeSupplier, Deployer
from eth_abi import encode
from eth_abi.packed import encode_packed

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    # Five accounts are created
    root = accounts[0]
    other = accounts[1]
    recipient0 = accounts[2]
    recipient1 = accounts[3]
    recipient2 = accounts[4]

    # An ERC20 token is deployed
    token = Nofee.deploy(root, root, chain[-1].timestamp + 3600, {'from': root})

    return root, other, recipient0, recipient1, recipient2, token

def test_supplier(chain, deployment, request, worker_id):
    root, other, recipient0, recipient1, recipient2, token = deployment

    # The list of recipients, amounts, and block numbers for each release.
    recipients = [
        recipient0.address,
        recipient1.address,
        recipient2.address,
        recipient0.address,
        recipient1.address,
        recipient2.address
    ]
    amounts = [1000, 2000, 3000, 4000, 5000, 6000]
    block = chain[-1].number
    blockNumbers = [
        block + 10,
        block + 20,
        block + 30,
        block + 40,
        block + 50,
        block + 60
    ]

    # A deployer contract is deployed to using which 'nofeeSupplier' is
    # deployed. This way, the address of 'nofeeSupplier' is deterministic and
    # an approval can be granted a priori.
    deployer = Deployer.deploy(root, {'from': root}) # chain[-1].number == block + 1

    # Deployment seed for 'nofeeSupplier'
    seed = 1

    # The deterministic address for 'nofeeSupplier'.
    supplier = deployer.addressOf(seed)

    # An approval is granted prior to the deployment of 'nofeeSupplier'.
    token.approve(supplier, sum(amounts), {'from': root}) # chain[-1].number == block + 2

    # 'nofeeSupplier' is deployed. 
    tx = deployer.create3(
        seed,
        NofeeSupplier.bytecode + encode(
            ['address', 'address', 'bytes'],
            [
                root.address,
                token.address,
                encode_packed(
                    ['address', 'uint96', 'uint32'] * 6,
                    [recipients[0], amounts[0], blockNumbers[0]] + 
                    [recipients[1], amounts[1], blockNumbers[1]] + 
                    [recipients[2], amounts[2], blockNumbers[2]] + 
                    [recipients[3], amounts[3], blockNumbers[3]] + 
                    [recipients[4], amounts[4], blockNumbers[4]] + 
                    [recipients[5], amounts[5], blockNumbers[5]]
                )
            ]
        ).hex(),
        {'from': root}
    ) # chain[-1].number == block + 3
    supplier = NofeeSupplier.at(supplier)

    # We attempt to release the first payment which reverts because:
    # 'blockNumbers[0] >= block + 4'
    with brownie.reverts('TooEarly: ' + str(block + 4) + ', ' + str(blockNumbers[0])):
        supplier.release([0], {'from': other}) # chain[-1].number == block + 5

    # We now proceed 10 blocks forward
    chain.mine(10) # chain[-1].number == block + 15

    # We attempt to release the first payment which is successful because
    # 'blockNumbers[0] < block + 15'
    supplier.release([0], {'from': other}) # chain[-1].number == block + 16

    # We verify the recipient's access after the release by checking its allowance
    assert token.allowance(supplier, recipients[0]) == amounts[0]

    # We attempt to release the first payment again which reverts.
    with brownie.reverts('PaymentReleasedOrForfeitedAlready: 0'):
        supplier.release([0], {'from': other}) # chain[-1].number == block + 17

    # We attempt to release the second payment which reverts because:
    # 'blockNumbers[1] >= block + 17'
    with brownie.reverts('TooEarly: ' + str(block + 17) + ', ' + str(blockNumbers[1])):
        supplier.release([1], {'from': other}) # chain[-1].number == block + 18

    # We now proceed 25 blocks forward
    chain.mine(25) # chain[-1].number == block + 43

    # We attempt to release the second and the third payments which succeeds
    supplier.release([1, 2], {'from': other}) # chain[-1].number == block + 44

    # We verify the recipient's access after the release by checking their allowance
    assert token.allowance(supplier, recipient1) == amounts[1]
    assert token.allowance(supplier, recipient2) == amounts[2]

    # We now proceed 25 blocks forward
    chain.mine(25) # chain[-1].number == block + 69

    # We attempt to release the forth payment which is successful because
    # 'blockNumbers[3] < block + 69'
    supplier.release([3], {'from': other})

    # We verify the recipient's access after the release by checking its allowance
    assert token.allowance(supplier, recipient0) == amounts[0] + amounts[3]

    # We attempt to forfeit the forth payment which reverts because it is already claimed.
    with brownie.reverts('PaymentReleasedOrForfeitedAlready: 3'):
        supplier.release([3], {'from': other})

    # We now forfeit the fifth and the sixth payment which is successful.
    supplier.forfeit([4, 5], {'from': root})

    # We attempt to release the fifth payment which reverts because the payment
    # is already claimed.
    with brownie.reverts('PaymentReleasedOrForfeitedAlready: 4'):
        supplier.release([4], {'from': other})

    # We attempt to release the sixth payment which reverts because the payment
    # is already claimed.
    with brownie.reverts('PaymentReleasedOrForfeitedAlready: 5'):
        supplier.release([5], {'from': other})

    # Recipients make transfers out of their entire allowances.
    token.transferFrom(supplier, recipient0, amounts[0] + amounts[3], {'from': recipient0})
    token.transferFrom(supplier, recipient1, amounts[1], {'from': recipient1})
    token.transferFrom(supplier, recipient2, amounts[2], {'from': recipient2})

    # The residual amount in 'nofeeSupplier' must be zero.
    assert token.balanceOf(supplier) == 0