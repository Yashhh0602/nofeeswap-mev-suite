from brownie import accounts, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply
from Nofee import encodeKernelCompact, encodeCurve, toInt, twosComplementInt8, dataGeneration

def main():
    root = accounts[0]
    owner = accounts[1]

    nofeeswap = Nofeeswap.at('0x0448f5446324e36eDcf2d05CbDD1F1b660042897')
    delegatee = NofeeswapDelegatee.at('0x9f3e8756Cf5B5E875Efe8f4F9D152Bb34F752BB6')
    token0 = ERC20FixedSupply.at('0x8464135c8F25Da09e49BC8782676a84730C318bC')
    token1 = ERC20FixedSupply.at('0x71C95911E9a5D330f4D621842EC243EE1343292e')

    # Use same data generation as the tests
    initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(10)

    kernel = initializations['kernel'][0]
    curve = initializations['curve'][0]

    logOffset = -5
    n = 1
    unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0 << 160) + 0

    tag0 = min(toInt(token0.address), toInt(token1.address))
    tag1 = max(toInt(token0.address), toInt(token1.address))

    print(f"kernel: {kernel}")
    print(f"curve: {curve}")

    tx = nofeeswap.dispatch(
        delegatee.initialize.encode_input(
            unsaltedPoolId,
            tag0,
            tag1,
            0x800000000000,
            encodeKernelCompact(kernel),
            encodeCurve(curve),
            b""
        ),
        {'from': owner}
    )
    print("✅ Pool initialized! tx:", tx.txid)
    print("   unsaltedPoolId:", hex(unsaltedPoolId))
    print("   tag0:", hex(tag0))
    print("   tag1:", hex(tag1))
