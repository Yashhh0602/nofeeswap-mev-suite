# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Nofee, TreasuryVester

@pytest.fixture(scope="module", autouse=True)
def deployment(module_isolation, chain):
    # Two accounts are created
    root = accounts[0]
    other = accounts[1]

    # An ERC20 token is deployed
    token = Nofee.deploy(root, root, chain[-1].timestamp + 3600, {'from': root})

    # 'treasuryVester' is deplyed
    vestingAmount = 100
    vestingPeriod = 60 * 60 * 24 * 365
    vestingBegin = chain[-1].timestamp + 60
    vestingCliff = chain[-1].timestamp + 60 * 2
    vestingEnd = chain[-1].timestamp + vestingPeriod
    treasuryVester = TreasuryVester.deploy(
        token,
        root,
        vestingAmount,
        vestingBegin,
        vestingCliff,
        vestingEnd,
        {'from': root}
    )

    # transfer the vesting amount to "treasuryVester"
    token.transfer(treasuryVester, vestingAmount, {'from': root})

    return root, other, token, vestingPeriod, vestingAmount, treasuryVester

def test_setRecipient(deployment, request, worker_id):
    root, other, token, vestingPeriod, vestingAmount, treasuryVester = deployment

    # An unauthorized account attempts to change the recipient which reverts
    with brownie.reverts('OnlyByRecipient: ' + other.address.lower() + ', ' + root.address.lower()):
        treasuryVester.setRecipient(other, {'from': other})

    # The authorized account attempts to change the recipient which succeeds
    treasuryVester.setRecipient(other, {'from': root})

def test_claim(chain, deployment, request, worker_id):
    root, other, token, vestingPeriod, vestingAmount, treasuryVester = deployment

    # We attempt to make a claim prior to the vesting cliff which reverts
    with brownie.reverts():
        treasuryVester.claim({'from': root})

    # We now proceed forward to the middle of the vesting period
    chain.sleep(vestingPeriod // 2)

    # We now make a claim which is successful and releases half of the vested amount
    treasuryVester.claim({'from': root})

    # We verify that the correct amount is released
    assert abs(token.balanceOf(other) - vestingAmount // 2) <= 1

    # We now proceed forward to the end of the vesting period
    chain.sleep(vestingPeriod // 2)

    # We now make a claim which is successful and releases the other half of the vested amount
    treasuryVester.claim({'from': root})

    # We verify that the correct amount is released
    assert token.balanceOf(other) == vestingAmount