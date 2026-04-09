# NoFeeSwap Core

NoFeeSwap is an Automated Market Making (AMM) protocol that introduces customizable liquidity curves with protocol-level security. This architecture enables zero spread between buy and sell marginal prices while ensuring that liquidity grows after every swap. This combination translates to higher trading activity, even during minor market price fluctuations, and drives greater profitability for liquidity providers (LPs).

This repository contains the core logic for interacting with the singleton, initializing liquidity pools, and executing pool actions such as swaps and liquidity provisioning.

## YellowPaper Reference

A detailed description of NoFeeSwap’s core functionalities can be found in the [NoFeeSwap YellowPaper](https://github.com/NoFeeSwap/docs) and `core/contracts/utilities/Memory.sol`.

## Architecture

NoFeeSwap uses a singleton architecture, where all pools are managed through a single `NoFeeSwap.sol` contract. To interact with the singleton, integrators must first make a `INofeeswap.unlock` call. Once unlocked, the integrator's `IUnlockCallback.unlockCallback` is invoked, allowing execution of any of the following actions on the singleton contract or any of its pools:

- `INofeeswap.clear(Tag tag, uint256 amount)`
- `INofeeswap.take(address token, address to, uint256 amount)`
- `INofeeswap.take(address token, uint256 tokenId, address to, uint256 amount)`
- `INofeeswap.take(address token, uint256 tokenId, address to, uint256 amount, bytes transferData)`
- `INofeeswap.settle()`
- `INofeeswap.transferTransientBalanceFrom(address sender, address receiver, Tag tag, uint256 amount)`
- `INofeeswap.modifyBalance(address owner, Tag tag, int256 amount)`
- `INofeeswap.modifyBalance(address owner, Tag tag0, Tag tag1, int256 amount0, int256 amount1)`
- `INofeeswap.swap(uint256 poolId, int256 amountSpecified, X59 logPriceLimit, uint256 zeroForOne, bytes hookData)`
- `INofeeswapDelegatee.modifyPosition(uint256 poolId, X59 logPriceMin, X59 logPriceMax, int256 shares, bytes hookData)`
- `INofeeswapDelegatee.donate(uint256 poolId, uint256 shares, bytes hookData)`

Note that pool initialization can happen outside the context of unlocking the NoFeeSwap.

Only the net balances owed to the user (negative) or to the singleton (positive) are tracked throughout the duration of an unlock. Any number of actions can be run on any pools, as long as the deltas accumulated during the unlock reach 0 by the unlock’s release. This unlock and call style architecture gives callers maximum flexibility in integrating with the core code.

Additionally, a pool may be initialized with a hook contract, that can implement any of the following callbacks in the lifecycle of pool actions:

- {pre,post}Initialize
- {pre,mid,post}Mint
- {pre,mid,post}Burn
- {pre,mid,post}Swap
- {pre,mid,post}Donate
- {pre,mid,post}ModifyKernel

The callback logic may be updated by the hooks dependent on their implementation.

## Repository Structure

- All contracts are held within the `core/contracts` folder.
  - `core/contracts/callback`: An interface provided to be inhereted by integrators.
  - `core/contracts/helpers`: Helper contracts used by tests are held in this folder.
  - `core/contracts/hooks`: Necessary tools for hook contracts are included in this folder.
  - `core/contracts/interfaces`: Contains all contract interfaces.
  - `core/contracts/utilities`: Contains data types the majority of core logic/functionalities.
- A list of disclaimers are included in the `core/docs` folder.
- Echidna fuzz tests are included in the `core/echidna` folder.
- Brownie unit tests are included in the `core/tests` folder.

```markdown
contracts/
----callback/
    | IUnlockCallback.sol
----helpers/
    | Access.sol
    | AmountWrapper.sol
    | ...
----hooks/
    | BaseHook.sol
    | HookCalldata.sol
----interfaces/
    | INofeeswap.sol
    | INofeeswapDelegatee.sol
    | ...
----utilities/
    | Amount.sol
    | Calldata.sol
    | ...
----Nofeeswap.sol
----NofeeswapDelegatee.sol
...
docs/
----disclaimers-core.pdf
echidna/
tests/
    | Amount_test.py
    | ...
```

## Setup Instructions

To get started, first install the following system dependencies:
```bash
sudo apt update
sudo apt install build-essential python3-dev python3.12-dev python3.12-venv npm
```
Clone the repo and its submodules
```bash
git clone https://github.com/NoFeeSwap/core.git
cd core
git submodule update --init --depth 1
```
Install hardhat
```bash
npm install hardhat@2.24.0 --save-dev
```
Create and initialize a Python virtual environment
```bash
python3.12 -m venv nofeeswap-core
source nofeeswap-core/bin/activate
```
Install the Python dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

## Running Tests

All of the Brownie unit tests can be run with the following command:
```bash
brownie test -n auto --network hardhat
```
Individual tests can be run as follows:
```bash
brownie test ./tests/Tag_test.py --network hardhat --interactive
```

In order to run the fuzz tests, first install [echidna](https://github.com/crytic/echidna) and then any of the following components can be run:
```bash
echidna ./echidna/IntegralTest.sol --contract IntegralTest --config ./echidna/echidna.config.Integral.yml
```
```bash
echidna ./echidna/SearchIncomingTest.sol --contract SearchIncomingTest --config ./echidna/echidna.config.SearchIncoming.yml
```
```bash
echidna ./echidna/SearchOutgoingTest.sol --contract SearchOutgoingTest --config ./echidna/echidna.config.SearchOutgoing.yml
```
```bash
echidna ./echidna/SearchOvershootTest.sol --contract SearchOvershootTest --config ./echidna/echidna.config.SearchOvershoot.yml
```

## Usage

The [Operator repo](https://github.com/NoFeeSwap/operator) enables interacting with the core functionalities.

## Disclaimers

NoFeeSwap is a research-driven protocol. While it introduces features designed to improve trading efficiency and LP incentives, there is no guarantee of profitability or performance. Users should conduct their own due diligence and assume full responsibility for interacting with the protocol. See core disclaimers [here](https://github.com/NoFeeSwap/core/blob/main/docs/disclaimers-core.pdf).

## License

Copyright 2025, NoFeeSwap LLC - All rights reserved. See [LICENSE](https://github.com/NoFeeSwap/core/blob/main/LICENSE) for details.