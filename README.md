# NoFeeSwap Assignment

## Transparency Statement

| Task | Status | Notes |
|------|--------|-------|
| Task 1 — Protocol Deployment | Complete | Deployed via Brownie on Anvil |
| Task 2a — Wallet Connection | Complete | MetaMask via wagmi + viem |
| Task 2b — Initialize Pool | Complete | Pool initialized via brownie script |
| Task 2c — Manage Liquidity | Complete (UI) | On-chain reverts due to pool ID encoding difference |
| Task 2d — Swap Interface | Complete (UI) | On-chain reverts due to pool ID encoding difference |
| Task 3a — Mempool Monitoring | Complete | Detects pending swaps via eth_getBlockByNumber |
| Task 3b — Calldata Decoding | Complete | Decodes zeroForOne, amountSpecified |
| Task 3c — Sandwich Execution | Demonstrated | Front-run and back-run broadcast with correct gas ordering |

**Known limitation:** NoFeeSwap uses a custom pool ID format, not keccak256(token+fee) like Uniswap v3. The frontend and bot use Uniswap-style pool IDs causing on-chain reverts for swap/liquidity. Mempool detection and sandwich ordering are fully functional.

## Prerequisites

- Python 3.12, Brownie 1.20.7
- Node.js 20.x, pnpm
- Foundry (anvil, cast)
- MetaMask browser extension

## Setup

### 1. Start local node
```bash
~/.foundry/bin/anvil --no-mining
```

### 2. Deploy contracts
```bash
cd contracts/core
rm -rf build/deployments && mkdir -p build/deployments/31337
brownie run scripts/deploy.py --network anvil-local
# Mine blocks when stuck: cast rpc anvil_mine --rpc-url http://127.0.0.1:8545
```

### 3. Initialize pool
```bash
cp tests/Nofee.py .
brownie run scripts/init_pool.py --network anvil-local
```

### 4. Save state
```bash
cast rpc anvil_dumpState --rpc-url http://127.0.0.1:8545 > anvil-state.json
```

### 5. Start frontend
```bash
cd frontend
nvm use 20
pnpm install
pnpm dev
# Open http://localhost:3000
```

### 6. Fund bot wallet
```bash
cast send <TOKEN0> "transfer(address,uint256)" <BOT_ADDRESS> 1000000000000000000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <OWNER_PRIVATE_KEY>
cast rpc anvil_mine --rpc-url http://127.0.0.1:8545
```

### 7. Start sandwich bot
```bash
cd bot
cp .env.example .env  # fill in values
npx ts-node src/bot.ts
```

### 8. Trigger attack
Submit a swap from the frontend, then mine a block:
```bash
cast rpc anvil_mine --rpc-url http://127.0.0.1:8545
```

## Bot Architecture

**Mempool monitoring:** Polls `eth_getBlockByNumber("pending", true)` every 500ms. Requires `--no-mining` so transactions stay pending.

**Target detection:** Filters by `tx.to == NOFEESWAP`, `tx.from == VICTIM`, `tx.input starts with 0x2a5a0c9e` (swap selector).

**Calldata decoding:** Uses ethers.js `Interface.parseTransaction()` to extract `zeroForOne`, `amountSpecified`, `sqrtPriceLimitX96`.

**Sandwich execution:**
1. Front-run: `gasPrice = baseGas * 2` → mines before victim
2. Victim swap executes at worse price
3. Back-run: `gasPrice = baseGas / 2` → mines after victim

Nonce ordering: `botNonce` for front-run, `botNonce + 1` for back-run.

## Known Limitations

1. Pool ID encoding mismatch between frontend/bot (Uniswap v3 style) and NoFeeSwap (custom format)
2. Profitability check simplified — no quoter simulation
3. Single hardcoded victim address
4. No WebSocket subscription (uses polling instead)

## Contract Addresses (Anvil local, chain 31337)

| Contract | Address |
|----------|---------|
| Nofeeswap | 0x0448f5446324e36eDcf2d05CbDD1F1b660042897 |
| NofeeswapDelegatee | 0x9f3e8756Cf5B5E875Efe8f4F9D152Bb34F752BB6 |
| Token0 | 0x8464135c8F25Da09e49BC8782676a84730C318bC |
| Token1 | 0x71C95911E9a5D330f4D621842EC243EE1343292e |
