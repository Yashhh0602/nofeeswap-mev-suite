import { ethers } from 'ethers'
import * as dotenv from 'dotenv'
dotenv.config()

const RPC_URL         = process.env.RPC_URL!
const BOT_PRIVATE_KEY = process.env.BOT_PRIVATE_KEY!
const VICTIM_ADDRESS  = process.env.VICTIM_ADDRESS!.toLowerCase()
const NOFEESWAP       = process.env.NOFEESWAP_ADDRESS!
const TOKEN0          = process.env.TOKEN0_ADDRESS!
const TOKEN1          = process.env.TOKEN1_ADDRESS!

const SWAP_ABI = [
  'function swap(bytes32 poolId, address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes hookData) returns (int256, int256)',
]
const ERC20_ABI = [
  'function approve(address spender, uint256 amount) returns (bool)',
  'function balanceOf(address) view returns (uint256)',
]

const SWAP_SELECTOR = '0x2a5a0c9e'

const provider  = new ethers.JsonRpcProvider(RPC_URL)
const botWallet = new ethers.Wallet(BOT_PRIVATE_KEY, provider)
const swapIface = new ethers.Interface(SWAP_ABI)

const log = (msg: string) => console.log(`[${new Date().toISOString()}] ${msg}`)
const sep = () => console.log('─'.repeat(70))

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

function isProfitable(swap: DecodedSwap): boolean {
  const absAmount = swap.amountSpecified < 0n ? -swap.amountSpecified : swap.amountSpecified
  const ONE_TOKEN = ethers.parseUnits('1', 18)
  return absAmount >= ONE_TOKEN
}

async function mineBlock() {
  await provider.send('evm_mine', [])
  log('⛏  Block mined')
}

async function ensureApproval(tokenAddr: string, amount: bigint) {
  const token = new ethers.Contract(tokenAddr, ERC20_ABI, botWallet)
  const tx = await token.approve(NOFEESWAP, amount)
  await tx.wait()
}

async function executeSandwich(victimTxHash: string, swap: DecodedSwap) {
  sep()
  log(`🎯 SANDWICH TARGET: ${victimTxHash.slice(0, 20)}…`)
  log(`   zeroForOne: ${swap.zeroForOne}`)
  log(`   amount:     ${ethers.formatUnits(
    swap.amountSpecified < 0n ? -swap.amountSpecified : swap.amountSpecified, 18
  )} tokens`)

  const swapContract = new ethers.Contract(NOFEESWAP, SWAP_ABI, botWallet)
  const botNonce     = await provider.getTransactionCount(botWallet.address, 'pending')
  const feeData      = await provider.getFeeData()
  const baseGas      = feeData.gasPrice ?? ethers.parseUnits('1', 'gwei')

  log('🔑 Approving tokens for bot…')
  const approveAmount = ethers.parseUnits('10000', 18)
  const tokenIn = swap.zeroForOne ? TOKEN0 : TOKEN1
  await ensureApproval(tokenIn, approveAmount)

  const MIN_SQRT = 4295128740n
  const MAX_SQRT = 1461446703485210103287273052203988822378723970341n
  const frontrunSqrt = swap.zeroForOne ? MIN_SQRT : MAX_SQRT
  const backrunSqrt  = swap.zeroForOne ? MAX_SQRT : MIN_SQRT

  // ── FRONT-RUN ────────────────────────────────────────────────────────────
  log('🟢 Sending FRONT-RUN (higher gas)…')
  try {
    const tx = await swapContract.swap(
      swap.poolId, botWallet.address, swap.zeroForOne,
      swap.amountSpecified, frontrunSqrt, '0x',
      { nonce: botNonce, gasPrice: baseGas * 2n, gasLimit: 500_000n }
    )
    log(`   Tx: ${tx.hash}`)
  } catch (e: unknown) {
    log(`   ⚠️  Front-run failed: ${e instanceof Error ? e.message.slice(0, 80) : e}`)
  }

  log('⛏  Mining block (front-run + victim)…')
  await mineBlock()

  // ── BACK-RUN ─────────────────────────────────────────────────────────────
  log('🔴 Sending BACK-RUN (lower gas)…')
  try {
    const tx = await swapContract.swap(
      swap.poolId, botWallet.address, !swap.zeroForOne,
      swap.amountSpecified, backrunSqrt, '0x',
      { nonce: botNonce + 1, gasPrice: baseGas / 2n, gasLimit: 500_000n }
    )
    log(`   Tx: ${tx.hash}`)
  } catch (e: unknown) {
    log(`   ⚠️  Back-run failed: ${e instanceof Error ? e.message.slice(0, 80) : e}`)
  }

  log('⛏  Mining block (back-run)…')
  await mineBlock()

  sep()
  log('✅ Sandwich complete')

  const t0 = new ethers.Contract(TOKEN0, ERC20_ABI, provider)
  const t1 = new ethers.Contract(TOKEN1, ERC20_ABI, provider)
  const b0 = await t0.balanceOf(botWallet.address)
  const b1 = await t1.balanceOf(botWallet.address)
  log(`   Bot TK0: ${ethers.formatUnits(b0, 18)}`)
  log(`   Bot TK1: ${ethers.formatUnits(b1, 18)}`)
  sep()
}

async function main() {
  log('🤖 Sandwich bot started')
  log(`   Watching victim: ${VICTIM_ADDRESS}`)
  log(`   NoFeeSwap:       ${NOFEESWAP}`)
  log(`   Bot wallet:      ${botWallet.address}`)
  sep()

  const processed = new Set<string>()

  setInterval(async () => {
    try {
      const pending = await provider.send('eth_getBlockByNumber', ['pending', true])
      if (!pending?.transactions?.length) return

      for (const tx of pending.transactions as any[]) {
        if (processed.has(tx.hash)) continue
        if (!tx.to) continue

        const isToNFS      = tx.to.toLowerCase() === NOFEESWAP.toLowerCase()
        const isFromVictim = tx.from?.toLowerCase() === VICTIM_ADDRESS
        const isSwap       = tx.input?.startsWith(SWAP_SELECTOR)

        if (!isToNFS || !isFromVictim || !isSwap) continue

        processed.add(tx.hash)
        log(`👀 Pending swap detected! Hash: ${tx.hash}`)

        const swap = decodeSwapCalldata(tx.input!)
        if (!swap) { log('   ⚠️  Could not decode calldata'); continue }

        if (!isProfitable(swap)) { log('   📉 Not profitable, skipping'); continue }

        await executeSandwich(tx.hash, swap)
      }
    } catch {}
  }, 500)
}

main().catch(console.error)
