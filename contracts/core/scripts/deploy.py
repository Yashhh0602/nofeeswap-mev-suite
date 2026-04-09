from brownie import accounts, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, DeployerHelper, network
from eth_abi import encode
import json, os

def main():
    print(f"Connected to: {network.show_active()}")

    root = accounts[0]
    owner = accounts[1]

    print(f"Root:  {root.address}")
    print(f"Owner: {owner.address}")

    print("\n[1/5] Deploying DeployerHelper...")
    deployer = DeployerHelper.deploy(root.address, {'from': root})
    print(f"      DeployerHelper: {deployer.address}")

    delegatee_address = deployer.addressOf(1)
    nofeeswap_address = deployer.addressOf(2)
    print(f"\n[2/5] Pre-computed addresses:")
    print(f"      Delegatee: {delegatee_address}")
    print(f"      Nofeeswap: {nofeeswap_address}")

    print("\n[3/5] Deploying NofeeswapDelegatee...")
    delegatee_bytecode = NofeeswapDelegatee.bytecode + encode(['address'], [nofeeswap_address]).hex()
    deployer.create3(1, delegatee_bytecode, {'from': root})
    delegatee = NofeeswapDelegatee.at(delegatee_address)
    print(f"      Deployed: {delegatee.address}")

    print("\n[4/5] Deploying Nofeeswap core...")
    nofeeswap_bytecode = Nofeeswap.bytecode + encode(['address', 'address'], [delegatee_address, root.address]).hex()
    deployer.create3(2, nofeeswap_bytecode, {'from': root})
    nofeeswap = Nofeeswap.at(nofeeswap_address)
    print(f"      Deployed: {nofeeswap.address}")

    print("\n      Configuring protocol...")
    protocol_config = (123 << 208) + (456 << 160) + int(root.address, 16)
    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(protocol_config), {'from': root})
    print("      Done.")

    print("\n[5/5] Deploying tokens...")
    token0 = ERC20FixedSupply.deploy("TokenA", "TKA", 2**120, owner.address, {'from': owner})
    token1 = ERC20FixedSupply.deploy("TokenB", "TKB", 2**120, owner.address, {'from': owner})
    print(f"      Token0: {token0.address}")
    print(f"      Token1: {token1.address}")

    addresses = {
        "nofeeswap": nofeeswap.address,
        "nofeeswapDelegatee": delegatee.address,
        "token0": token0.address,
        "token1": token1.address,
        "owner": owner.address,
        "root": root.address,
    }

    out_path = os.path.expanduser("~/nofeeswap-assignment/deployments/addresses.json")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w') as f:
        json.dump(addresses, f, indent=2)

    print("\n✅ Done! Addresses saved to deployments/addresses.json")
    for k, v in addresses.items():
        print(f"   {k:<25} {v}")
