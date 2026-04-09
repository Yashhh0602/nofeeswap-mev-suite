# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Sentinel, Deployer
from eth_abi import encode
from Nofee import _tag0_, _msgSender_, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, getPoolId

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    admin0 = accounts[2]
    admin1 = accounts[3]
    other = accounts[4]
    deployer = Deployer.deploy(root, {'from': root})
    delegatee = deployer.addressOf(1)
    nofeeswap = deployer.addressOf(2)
    deployer.create3(
        1,
        NofeeswapDelegatee.bytecode + encode(
            ['address'],
            [nofeeswap]
        ).hex(), 
        {'from': root}
    )
    deployer.create3(
        2,
        Nofeeswap.bytecode + encode(
            ['address', 'address'],
            [delegatee, root.address]
        ).hex(), 
        {'from': root}
    )
    delegatee = NofeeswapDelegatee.at(delegatee)
    nofeeswap = Nofeeswap.at(nofeeswap)
    access = Access.deploy({'from': root})
    hook = MockHook.deploy({'from': root})
    reward = ERC20FixedSupply.deploy("Reward", "Reward", 2**120, root, {'from': root})

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, root, {'from': root})

    return root, owner, admin0, admin1, other, nofeeswap, delegatee, access, hook, token0, token1, reward

def test_sentinel(deployment, request, worker_id):
    root, owner, admin0, admin1, other, nofeeswap, delegatee, access, hook, token0, token1, reward = deployment

    initializationCost0 = 100
    initializationCost1 = 200

    growthPortionCost0 = 50000
    growthPortionCost1 = 10000

    maxPoolGrowthPortionDefault = 0x700000000000
    protocolGrowthPortionDefault = 0x35000000000

    maxPoolGrowthPortionSentinel = 0x50000000000
    protocolGrowthPortionSentinel = 0x5500000000

    poolGrowthPortion0 = 0x350000000000
    poolGrowthPortion1 = 0x450000000000
    poolGrowthPortion2 = 0x550000000000

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (maxPoolGrowthPortionDefault << 208) + (protocolGrowthPortionDefault << 160) + int(root.address, 16)
    ), {'from': root})

    sentinel = Sentinel.deploy(nofeeswap, other, reward, initializationCost0, growthPortionCost0, admin0, {'from': root})

    assert sentinel.nofeeswap() == nofeeswap.address
    assert sentinel.exempt() == other.address
    assert sentinel.token() == reward.address
    assert sentinel.initializationCost() == initializationCost0
    assert sentinel.growthPortionCost() == growthPortionCost0
    assert sentinel.admin() == admin0.address

    nofeeswap.dispatch(delegatee.modifySentinel.encode_input(sentinel), {'from': root})

    kernel = [
      [0, 0],
      [2 ** 40, 2 ** 15]
    ]
    curve = [2 ** 40 + 1, 2 ** 40 + 1 + 2 ** 40]

    tag0 = min(toInt(token0.address), toInt(token1.address))
    tag1 = max(toInt(token0.address), toInt(token1.address))

    sentinelInput = encode(['uint256'] * 100, [0] * 100)[0 : _tag0_ - _msgSender_] + tag0.to_bytes(32, 'big') + tag1.to_bytes(32, 'big')

    logOffset = -5
    unsaltedPoolId0 = (0 << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    unsaltedPoolId1 = (1 << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    unsaltedPoolId2 = (2 << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    unsaltedPoolId3 = (3 << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)

    poolId0 = getPoolId(owner.address, unsaltedPoolId0)
    poolId1 = getPoolId(owner.address, unsaltedPoolId1)
    poolId2 = getPoolId(other.address, unsaltedPoolId2)
    poolId3 = getPoolId(owner.address, unsaltedPoolId3)

    reward.approve(sentinel, initializationCost0 // 2, {'from': owner})

    with brownie.reverts("ERC20InsufficientAllowance: " + sentinel.address.lower() + ', ' + str(reward.allowance(owner, sentinel)) + ', ' + str(initializationCost0)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId0,
              tag0,
              tag1,
              0,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b"HookData"
          ),
          {'from': owner}
        )

    with brownie.reverts("ERC20InsufficientAllowance: " + sentinel.address.lower() + ', ' + str(reward.allowance(owner, sentinel)) + ', ' + str(initializationCost0)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId0,
              tag0,
              tag1,
              poolGrowthPortion0 // 2,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b"HookData"
          ),
          {'from': owner}
        )

    reward.approve(sentinel, initializationCost0, {'from': owner})
    reward.transfer(owner, initializationCost0 // 2, {'from': root})

    with brownie.reverts("ERC20InsufficientBalance: " + owner.address.lower() + ', ' + str(reward.balanceOf(owner)) + ', ' + str(initializationCost0)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId0,
              tag0,
              tag1,
              0,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b"HookData"
          ),
          {'from': owner}
        )

    with brownie.reverts("ERC20InsufficientBalance: " + owner.address.lower() + ', ' + str(reward.balanceOf(owner)) + ', ' + str(initializationCost0)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId0,
              tag0,
              tag1,
              poolGrowthPortion0 // 2,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b"HookData"
          ),
          {'from': owner}
        )

    reward.transfer(owner, initializationCost0 - (initializationCost0 // 2), {'from': root})
    reward.approve(sentinel, initializationCost0 + (growthPortionCost0 // 2), {'from': owner})

    with brownie.reverts("ERC20InsufficientAllowance: " + sentinel.address.lower() + ', ' + str(reward.allowance(owner, sentinel) - initializationCost0) + ', ' + str(growthPortionCost0)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId0,
              tag0,
              tag1,
              poolGrowthPortion0 // 2,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b"HookData"
          ),
          {'from': owner}
        )

    reward.approve(sentinel, initializationCost0 + growthPortionCost0, {'from': owner})
    reward.transfer(owner, growthPortionCost0 // 2, {'from': root})

    with brownie.reverts("ERC20InsufficientBalance: " + owner.address.lower() + ', ' + str(reward.balanceOf(owner) - initializationCost0) + ', ' + str(growthPortionCost0)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId0,
              tag0,
              tag1,
              poolGrowthPortion0 // 2,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b"HookData"
          ),
          {'from': owner}
        )

    ############################

    reward.transfer(owner, growthPortionCost0 // 2, {'from': root})

    balanceOwner = reward.balanceOf(owner)
    balanceAdmin = reward.balanceOf(admin0)
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId1,
          tag0,
          tag1,
          poolGrowthPortion0,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b"HookData"
      ),
      {'from': owner}
    )
    assert reward.balanceOf(owner) == balanceOwner - initializationCost0 - growthPortionCost0
    assert reward.balanceOf(admin0) == balanceAdmin + initializationCost0 + growthPortionCost0
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId1)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId1, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId1, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    reward.approve(sentinel, initializationCost0, {'from': owner})
    reward.transfer(owner, initializationCost0, {'from': root})

    balanceOwner = reward.balanceOf(owner)
    balanceAdmin = reward.balanceOf(admin0)
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId0,
          tag0,
          tag1,
          0,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b"HookData"
      ),
      {'from': owner}
    )
    assert reward.balanceOf(owner) == balanceOwner - initializationCost0
    assert reward.balanceOf(admin0) == balanceAdmin + initializationCost0
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == 0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    balanceOther = reward.balanceOf(other)
    balanceAdmin = reward.balanceOf(admin0)
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId2,
          tag0,
          tag1,
          poolGrowthPortion0,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b"HookData"
      ),
      {'from': other}
    )
    assert reward.balanceOf(other) == balanceOther
    assert reward.balanceOf(admin0) == balanceAdmin
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    ############################

    with brownie.reverts("OnlyByAdmin: " + admin1.address.lower() + ", " + admin0.address.lower()):
        sentinel.setAdmin(admin1, {'from': admin1})

    tx = sentinel.setAdmin(admin1, {'from': admin0})
    assert sentinel.admin() == admin1.address
    tx.events["NewAdmin"]["oldAdmin"] == admin0.address
    tx.events["NewAdmin"]["newAdmin"] == admin1.address

    with brownie.reverts("TagsOutOfOrder: " + str(tag1) + ", " + str(tag0)):
        tx = sentinel.setGrowthPortions([tag1], [tag0], [maxPoolGrowthPortionSentinel], [protocolGrowthPortionSentinel], {'from': admin1})

    with brownie.reverts("UnequalLengths: " + str(1) + ", " + str(2)):
        tx = sentinel.setGrowthPortions([tag0], [tag1, tag1], [maxPoolGrowthPortionSentinel], [protocolGrowthPortionSentinel], {'from': admin1})

    with brownie.reverts("UnequalLengths: " + str(1) + ", " + str(2)):
        tx = sentinel.setGrowthPortions([tag0], [tag1], [maxPoolGrowthPortionSentinel, maxPoolGrowthPortionSentinel], [protocolGrowthPortionSentinel], {'from': admin1})

    with brownie.reverts("UnequalLengths: " + str(1) + ", " + str(2)):
        tx = sentinel.setGrowthPortions([tag0], [tag1], [maxPoolGrowthPortionSentinel], [protocolGrowthPortionSentinel, protocolGrowthPortionSentinel], {'from': admin1})

    assert sentinel.growthPortions(tag0, tag1) == 0

    maxPoolGrowthPortion, protocolGrowthPortion = sentinel.getGrowthPortions(sentinelInput)
    assert maxPoolGrowthPortion == 0xffffffffffff
    assert protocolGrowthPortion == 0xffffffffffff

    tx = sentinel.setGrowthPortions([tag0], [tag1], [maxPoolGrowthPortionSentinel], [0], {'from': admin1})
    assert sentinel.growthPortions(tag0, tag1) == (maxPoolGrowthPortionSentinel << 48) + 0xffffffffffff
    assert tx.events["NewSentinelGrowthPortions"]["tag0"] == tag0
    assert tx.events["NewSentinelGrowthPortions"]["tag1"] == tag1

    maxPoolGrowthPortion, protocolGrowthPortion = sentinel.getGrowthPortions(sentinelInput)
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId1
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId1)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId1, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId1, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId0
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == 0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId2
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == 0

    reward.approve(sentinel, initializationCost0 + growthPortionCost0, {'from': owner})
    reward.transfer(owner, initializationCost0 + growthPortionCost0, {'from': root})
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId3,
          tag0,
          tag1,
          poolGrowthPortion1,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b"HookData"
      ),
      {'from': owner}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId3)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId3, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId3, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion1
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == 0

    ############################

    tx = sentinel.setGrowthPortions([tag0], [tag1], [0], [protocolGrowthPortionSentinel], {'from': admin1})
    assert sentinel.growthPortions(tag0, tag1) == (0xffffffffffff << 48) + protocolGrowthPortionSentinel
    assert tx.events["NewSentinelGrowthPortions"]["tag0"] == tag0
    assert tx.events["NewSentinelGrowthPortions"]["tag1"] == tag1

    maxPoolGrowthPortion, protocolGrowthPortion = sentinel.getGrowthPortions(sentinelInput)
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId1
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId1)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId1, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId1, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId0
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == 0
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId2
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId3
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId3)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId3, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId3, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion1
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    ############################

    tx = sentinel.setGrowthPortions([tag0], [tag1], [maxPoolGrowthPortionSentinel], [protocolGrowthPortionSentinel], {'from': admin1})
    assert sentinel.growthPortions(tag0, tag1) == (maxPoolGrowthPortionSentinel << 48) + protocolGrowthPortionSentinel
    assert tx.events["NewSentinelGrowthPortions"]["tag0"] == tag0
    assert tx.events["NewSentinelGrowthPortions"]["tag1"] == tag1

    maxPoolGrowthPortion, protocolGrowthPortion = sentinel.getGrowthPortions(sentinelInput)
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId1
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId1)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId1, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId1, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId0
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == 0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId2
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId3
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId3)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId3, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId3, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion1
    assert maxPoolGrowthPortion == maxPoolGrowthPortionSentinel
    assert protocolGrowthPortion == protocolGrowthPortionSentinel

    ############################

    tx = sentinel.setGrowthPortions([tag0], [tag1], [0], [0], {'from': admin1})
    assert sentinel.growthPortions(tag0, tag1) == (0xffffffffffff << 48) + 0xffffffffffff
    assert tx.events["NewSentinelGrowthPortions"]["tag0"] == tag0
    assert tx.events["NewSentinelGrowthPortions"]["tag1"] == tag1

    maxPoolGrowthPortion, protocolGrowthPortion = sentinel.getGrowthPortions(sentinelInput)
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId1
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId1)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId1, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId1, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId0
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == 0
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId2
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == 0

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId3
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId3)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId3, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId3, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion1
    assert maxPoolGrowthPortion == 0
    assert protocolGrowthPortion == 0

    ############################

    tx = sentinel.setGrowthPortions([tag0], [tag1], [0xffffffffffff], [0xffffffffffff], {'from': admin1})
    assert sentinel.growthPortions(tag0, tag1) == 0
    assert tx.events["NewSentinelGrowthPortions"]["tag0"] == tag0
    assert tx.events["NewSentinelGrowthPortions"]["tag1"] == tag1

    maxPoolGrowthPortion, protocolGrowthPortion = sentinel.getGrowthPortions(sentinelInput)
    assert maxPoolGrowthPortion == 0xffffffffffff
    assert protocolGrowthPortion == 0xffffffffffff

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId1
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId1)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId1, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId1, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId0
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == 0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId2
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion0
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    tx = nofeeswap.dispatch(
      delegatee.updateGrowthPortions.encode_input(
          poolId3
      ),
      {'from': root}
    )
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId3)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId3, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId3, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion1
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    ############################

    with brownie.reverts("OnlyByAdmin: " + admin0.address.lower() + ", " + admin1.address.lower()):
        tx = sentinel.setInitializationCost(initializationCost1, {'from': admin0})

    tx = sentinel.setInitializationCost(initializationCost1, {'from': admin1})
    assert sentinel.initializationCost() == initializationCost1
    assert tx.events["NewInitializationCost"]["oldInitializationCost"] == initializationCost0
    assert tx.events["NewInitializationCost"]["newInitializationCost"] == initializationCost1

    ############################

    with brownie.reverts("OnlyByAdmin: " + admin0.address.lower() + ", " + admin1.address.lower()):
        tx = sentinel.setGrowthPortionCost(growthPortionCost1, {'from': admin0})

    tx = sentinel.setGrowthPortionCost(growthPortionCost1, {'from': admin1})
    assert sentinel.growthPortionCost() == growthPortionCost1
    assert tx.events["NewGrowthPortionCost"]["oldGrowthPortionCost"] == growthPortionCost0
    assert tx.events["NewGrowthPortionCost"]["newGrowthPortionCost"] == growthPortionCost1

    ############################

    reward.approve(sentinel, growthPortionCost1 // 2, {'from': owner})

    with brownie.reverts("ERC20InsufficientAllowance: " + sentinel.address.lower() + ', ' + str(reward.allowance(owner, sentinel)) + ', ' + str(growthPortionCost1)):
        tx = nofeeswap.dispatch(
          delegatee.modifyPoolGrowthPortion.encode_input(
              poolId0,
              poolGrowthPortion2
          ),
          {'from': owner}
        )

    reward.approve(sentinel, growthPortionCost1, {'from': owner})
    reward.transfer(owner, growthPortionCost1 // 2, {'from': root})

    with brownie.reverts("ERC20InsufficientBalance: " + owner.address.lower() + ', ' + str(reward.balanceOf(owner)) + ', ' + str(growthPortionCost1)):
        tx = nofeeswap.dispatch(
          delegatee.modifyPoolGrowthPortion.encode_input(
              poolId0,
              poolGrowthPortion2
          ),
          {'from': owner}
        )

    reward.transfer(owner, growthPortionCost1 // 2, {'from': root})

    balanceOwner = reward.balanceOf(owner)
    balanceAdmin = reward.balanceOf(admin1)
    tx = nofeeswap.dispatch(
      delegatee.modifyPoolGrowthPortion.encode_input(
          poolId0,
          poolGrowthPortion2
      ),
      {'from': owner}
    )
    assert reward.balanceOf(owner) == balanceOwner - growthPortionCost1
    assert reward.balanceOf(admin1) == balanceAdmin + growthPortionCost1
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion2
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    balanceOwner = reward.balanceOf(owner)
    balanceAdmin = reward.balanceOf(admin1)
    tx = nofeeswap.dispatch(
      delegatee.modifyPoolGrowthPortion.encode_input(
          poolId0,
          poolGrowthPortion2
      ),
      {'from': owner}
    )
    assert reward.balanceOf(owner) == balanceOwner
    assert reward.balanceOf(admin1) == balanceAdmin
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId0)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId0, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId0, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion2
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault

    balanceOther = reward.balanceOf(other)
    balanceAdmin = reward.balanceOf(admin1)
    tx = nofeeswap.dispatch(
      delegatee.modifyPoolGrowthPortion.encode_input(
          poolId2,
          poolGrowthPortion2
      ),
      {'from': other}
    )
    assert reward.balanceOf(other) == balanceOther
    assert reward.balanceOf(admin1) == balanceAdmin
    staticParamsStoragePointerExtension, growth, integral0, integral1, sharesTotal, staticParamsStoragePointer, logPriceCurrent = access._readDynamicParams(nofeeswap, poolId2)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId2, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId2, staticParamsStoragePointer)
    assert poolGrowthPortion == poolGrowthPortion2
    assert maxPoolGrowthPortion == maxPoolGrowthPortionDefault
    assert protocolGrowthPortion == protocolGrowthPortionDefault