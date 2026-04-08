'use client'
import { useState, useEffect } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { parseAbi, parseUnits, formatUnits, keccak256, encodeAbiParameters } from 'viem'
import { CONTRACTS, TOKEN0_SYMBOL, TOKEN1_SYMBOL } from '@/lib/contracts'
import Link from 'next/link'

const ERC20_ABI = parseAbi([
  'function approve(address spender, uint256 amount) returns (bool)',
  'function balanceOf(address) view returns (uint256)',
])

const CORE_ABI = parseAbi([
  'function swap(bytes32 poolId, address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata hookData) external returns (int256 amount0, int256 amount1)',
])

function computePoolId(t0: string, t1: string, fee: number): `0x${string}` {
  const [a, b] = [t0, t1].sort()
  return keccak256(encodeAbiParameters(
    [{ type: 'address' }, { type: 'address' }, { type: 'uint24' }],
    [a as `0x${string}`, b as `0x${string}`, fee]
  ))
}

const MIN_SQRT_RATIO = 4295128739n
const MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342n

type TxStatus = 'idle' | 'approving' | 'pending' | 'confirming' | 'success' | 'error'

export default function SwapPage() {
  const { address } = useAccount()
  const [zeroForOne, setZeroForOne] = useState(true)
  const [amountIn, setAmountIn] = useState('10')
  const [slippage, setSlippage] = useState(0.5)
  const [fee, setFee] = useState('3000')
  const [status, setStatus] = useState<TxStatus>('idle')
  const [txError, setTxError] = useState<string>()
  const [lastHash, setLastHash] = useState<`0x${string}` | undefined>()

  const { writeContractAsync } = useWriteContract()
  const { isSuccess: isMined } = useWaitForTransactionReceipt({ hash: lastHash })
  if (isMined && status === 'confirming') setStatus('success')

  const poolId = computePoolId(CONTRACTS.token0, CONTRACTS.token1, parseInt(fee))

  const tokenIn  = zeroForOne ? CONTRACTS.token0 : CONTRACTS.token1
  const tokenOut = zeroForOne ? CONTRACTS.token1 : CONTRACTS.token0
  const symIn    = zeroForOne ? TOKEN0_SYMBOL : TOKEN1_SYMBOL
  const symOut   = zeroForOne ? TOKEN1_SYMBOL : TOKEN0_SYMBOL

  const { data: balIn } = useReadContract({
    address: tokenIn as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })
  const { data: balOut } = useReadContract({
    address: tokenOut as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })

  // Estimated output: simplified 1:1 minus slippage for display (real quote would call quoter)
  const estimatedOut = amountIn && !isNaN(parseFloat(amountIn))
    ? (parseFloat(amountIn) * (1 - slippage / 100)).toFixed(4)
    : '—'
  const priceImpact = slippage.toFixed(2)

  const fmt = (v: bigint | undefined) =>
    v !== undefined ? parseFloat(formatUnits(v as bigint, 18)).toFixed(4) : '—'

  const handleSwap = async () => {
    if (!address || !amountIn) return
    try {
      setStatus('approving')
      const amt = parseUnits(amountIn, 18)

      const hApprove = await writeContractAsync({
        address: tokenIn as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [CONTRACTS.nofeeswap as `0x${string}`, amt],
      })
      setLastHash(hApprove)

      setStatus('pending')
      const sqrtLimit = zeroForOne ? MIN_SQRT_RATIO + 1n : MAX_SQRT_RATIO - 1n
      const hash = await writeContractAsync({
        address: CONTRACTS.nofeeswap as `0x${string}`,
        abi: CORE_ABI,
        functionName: 'swap',
        args: [poolId, address, zeroForOne, amt, sqrtLimit, '0x'],
      })
      setLastHash(hash)
      setStatus('confirming')
    } catch (e: unknown) {
      setTxError(e instanceof Error ? e.message.slice(0, 120) : 'Unknown error')
      setStatus('error')
    }
  }

  const statusUI: Record<TxStatus, { label: string; cls: string } | null> = {
    idle: null,
    approving:  { label: '⏳ Approving token spend…', cls: 'bg-yellow-900 border-yellow-600 text-yellow-200' },
    pending:    { label: '⏳ Awaiting MetaMask confirmation…', cls: 'bg-yellow-900 border-yellow-600 text-yellow-200' },
    confirming: { label: '⛏ Waiting for block confirmation…', cls: 'bg-blue-900 border-blue-600 text-blue-200' },
    success:    { label: '✅ Swap confirmed!', cls: 'bg-green-900 border-green-600 text-green-200' },
    error:      { label: `❌ ${txError}`, cls: 'bg-red-900 border-red-600 text-red-200' },
  }

  return (
    <main className="min-h-screen bg-black text-white p-8">
      <div className="max-w-md mx-auto">
        <Link href="/" className="text-gray-500 text-sm mb-6 block">← Back</Link>
        <h1 className="text-3xl font-bold mb-2">Swap</h1>
        <p className="text-gray-400 mb-6">Trade tokens instantly</p>

        <div className="bg-gray-900 border border-gray-700 rounded-xl p-6 space-y-4">

          {/* From */}
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex justify-between mb-2">
              <span className="text-sm text-gray-400">You pay</span>
              <span className="text-xs text-gray-500">Balance: {fmt(balIn as bigint)}</span>
            </div>
            <div className="flex items-center gap-3">
              <input
                type="number"
                value={amountIn}
                onChange={e => setAmountIn(e.target.value)}
                placeholder="0.0"
                className="flex-1 bg-transparent text-2xl font-bold outline-none"
              />
              <div className="bg-gray-700 rounded-full px-4 py-2 font-bold text-sm">{symIn}</div>
            </div>
          </div>

          {/* Flip */}
          <div className="flex justify-center">
            <button
              onClick={() => setZeroForOne(!zeroForOne)}
              className="bg-gray-800 hover:bg-gray-700 border border-gray-600 rounded-full p-2 text-lg transition-transform hover:rotate-180 duration-300">
              ⇅
            </button>
          </div>

          {/* To */}
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex justify-between mb-2">
              <span className="text-sm text-gray-400">You receive (est.)</span>
              <span className="text-xs text-gray-500">Balance: {fmt(balOut as bigint)}</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="flex-1 text-2xl font-bold text-green-400">{estimatedOut}</div>
              <div className="bg-gray-700 rounded-full px-4 py-2 font-bold text-sm">{symOut}</div>
            </div>
          </div>

          {/* Slippage */}
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex justify-between mb-2">
              <span className="text-sm text-gray-400">Slippage tolerance</span>
              <span className="text-green-400 font-bold text-sm">{slippage.toFixed(1)}%</span>
            </div>
            <input
              type="range" min="0.1" max="5" step="0.1"
              value={slippage}
              onChange={e => setSlippage(parseFloat(e.target.value))}
              className="w-full accent-green-400"
            />
            <div className="flex justify-between text-xs text-gray-600 mt-1">
              <span>0.1%</span><span>5%</span>
            </div>
            <div className="flex gap-2 mt-2">
              {[0.1, 0.5, 1.0].map(v => (
                <button key={v} onClick={() => setSlippage(v)}
                  className={`flex-1 py-1 rounded text-xs font-bold ${slippage === v ? 'bg-green-400 text-black' : 'bg-gray-700 text-gray-300'}`}>
                  {v}%
                </button>
              ))}
            </div>
          </div>

          {/* Price info */}
          {amountIn && (
            <div className="text-xs text-gray-400 space-y-1 px-1">
              <div className="flex justify-between">
                <span>Estimated output</span>
                <span className="text-white">{estimatedOut} {symOut}</span>
              </div>
              <div className="flex justify-between">
                <span>Price impact</span>
                <span className={parseFloat(priceImpact) > 2 ? 'text-red-400' : 'text-green-400'}>
                  ~{priceImpact}%
                </span>
              </div>
              <div className="flex justify-between">
                <span>Min. received</span>
                <span className="text-white">
                  {(parseFloat(estimatedOut) * (1 - slippage/100)).toFixed(4)} {symOut}
                </span>
              </div>
            </div>
          )}

          {/* Status */}
          {statusUI[status] && (
            <div className={`border rounded p-3 text-sm ${statusUI[status]!.cls}`}>
              {statusUI[status]!.label}
            </div>
          )}

          <button
            onClick={handleSwap}
            disabled={!address || !amountIn || ['approving','pending','confirming'].includes(status)}
            className="w-full bg-green-400 text-black font-bold py-4 rounded-xl text-lg hover:bg-green-300 disabled:opacity-50 transition-colors">
            {status === 'approving' ? 'Approving…' :
             status === 'pending' ? 'Check MetaMask…' :
             status === 'confirming' ? 'Confirming…' :
             `Swap ${symIn} → ${symOut}`}
          </button>
        </div>

        <div className="mt-4 text-xs text-gray-600 text-center">
          Pool fee: {parseInt(fee)/10000}% · Chain: Anvil (31337)
        </div>
      </div>
    </main>
  )
}
