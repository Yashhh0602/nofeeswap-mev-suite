'use client'
import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { parseAbi, parseUnits, keccak256, encodeAbiParameters } from 'viem'
import { CONTRACTS, TOKEN0_SYMBOL, TOKEN1_SYMBOL } from '@/lib/contracts'
import Link from 'next/link'

const ERC20_ABI = parseAbi([
  'function approve(address spender, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
])

const CORE_ABI = parseAbi([
  'function mint(bytes32 poolId, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata hookData) external returns (uint256 amount0, uint256 amount1)',
  'function burn(bytes32 poolId, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata hookData) external returns (uint256 amount0, uint256 amount1)',
])

function computePoolId(token0: string, token1: string, fee: number): `0x${string}` {
  const [t0, t1] = [token0, token1].sort()
  return keccak256(encodeAbiParameters(
    [{ type: 'address' }, { type: 'address' }, { type: 'uint24' }],
    [t0 as `0x${string}`, t1 as `0x${string}`, fee]
  ))
}

type TxStatus = 'idle' | 'approving' | 'pending' | 'confirming' | 'success' | 'error'

function StatusBadge({ status, error }: { status: TxStatus; error?: string }) {
  const map: Record<TxStatus, { label: string; cls: string }> = {
    idle:       { label: '',                    cls: '' },
    approving:  { label: '⏳ Approving token…', cls: 'bg-yellow-900 border-yellow-500 text-yellow-200' },
    pending:    { label: '⏳ Check MetaMask…',  cls: 'bg-yellow-900 border-yellow-500 text-yellow-200' },
    confirming: { label: '⛏ Confirming on-chain…', cls: 'bg-blue-900 border-blue-500 text-blue-200' },
    success:    { label: '✅ Transaction confirmed!', cls: 'bg-green-900 border-green-500 text-green-200' },
    error:      { label: `❌ ${error ?? 'Error'}`, cls: 'bg-red-900 border-red-500 text-red-200' },
  }
  const { label, cls } = map[status]
  if (!label) return null
  return <div className={`border rounded p-3 text-sm ${cls}`}>{label}</div>
}

export default function LiquidityPage() {
  const { address } = useAccount()
  const [tab, setTab] = useState<'mint' | 'burn'>('mint')
  const [fee, setFee] = useState('3000')
  const [tickLower, setTickLower] = useState('-887220')
  const [tickUpper, setTickUpper] = useState('887220')
  const [amount, setAmount] = useState('100')
  const [status, setStatus] = useState<TxStatus>('idle')
  const [txError, setTxError] = useState<string>()

  const poolId = computePoolId(CONTRACTS.token0, CONTRACTS.token1, parseInt(fee))

  const { writeContractAsync } = useWriteContract()
  const [lastHash, setLastHash] = useState<`0x${string}` | undefined>()
  const { isSuccess: isMined } = useWaitForTransactionReceipt({ hash: lastHash })

  const { data: bal0 } = useReadContract({
    address: CONTRACTS.token0 as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })
  const { data: bal1 } = useReadContract({
    address: CONTRACTS.token1 as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })

  const fmt = (v: bigint | undefined) =>
    v !== undefined ? (Number(v) / 1e18).toFixed(4) : '—'

  const handleMint = async () => {
    if (!address) return
    try {
      setStatus('approving')
      const amt = parseUnits(amount, 18)

      // Approve both tokens
      const h0 = await writeContractAsync({
        address: CONTRACTS.token0 as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [CONTRACTS.nofeeswap as `0x${string}`, amt * 2n],
      })
      setLastHash(h0)

      const h1 = await writeContractAsync({
        address: CONTRACTS.token1 as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [CONTRACTS.nofeeswap as `0x${string}`, amt * 2n],
      })
      setLastHash(h1)

      setStatus('pending')
      const hash = await writeContractAsync({
        address: CONTRACTS.nofeeswap as `0x${string}`,
        abi: CORE_ABI,
        functionName: 'mint',
        args: [poolId, parseInt(tickLower), parseInt(tickUpper), BigInt(amt), '0x'],
      })
      setLastHash(hash)
      setStatus('confirming')
    } catch (e: unknown) {
      setTxError(e instanceof Error ? e.message.slice(0, 120) : 'Unknown error')
      setStatus('error')
    }
  }

  const handleBurn = async () => {
    if (!address) return
    try {
      setStatus('pending')
      const hash = await writeContractAsync({
        address: CONTRACTS.nofeeswap as `0x${string}`,
        abi: CORE_ABI,
        functionName: 'burn',
        args: [poolId, parseInt(tickLower), parseInt(tickUpper), BigInt(parseUnits(amount, 18)), '0x'],
      })
      setLastHash(hash)
      setStatus('confirming')
    } catch (e: unknown) {
      setTxError(e instanceof Error ? e.message.slice(0, 120) : 'Unknown error')
      setStatus('error')
    }
  }

  if (isMined && status === 'confirming') setStatus('success')

  return (
    <main className="min-h-screen bg-black text-white p-8">
      <div className="max-w-2xl mx-auto">
        <Link href="/" className="text-gray-500 text-sm mb-6 block">← Back</Link>
        <h1 className="text-3xl font-bold mb-2">Manage Liquidity</h1>
        <p className="text-gray-400 mb-6">Add or remove liquidity from a pool</p>

        {/* Balances */}
        <div className="bg-gray-900 border border-gray-700 rounded p-4 mb-6 flex gap-8">
          <div>
            <p className="text-xs text-gray-500">{TOKEN0_SYMBOL} balance</p>
            <p className="text-lg font-bold text-green-400">{fmt(bal0 as bigint)}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500">{TOKEN1_SYMBOL} balance</p>
            <p className="text-lg font-bold text-green-400">{fmt(bal1 as bigint)}</p>
          </div>
        </div>

        {/* Tab */}
        <div className="flex gap-2 mb-6">
          {(['mint', 'burn'] as const).map(t => (
            <button key={t} onClick={() => { setTab(t); setStatus('idle') }}
              className={`flex-1 py-2 rounded font-bold capitalize ${tab === t ? 'bg-green-400 text-black' : 'bg-gray-800 text-gray-300'}`}>
              {t === 'mint' ? '+ Add Liquidity' : '− Remove Liquidity'}
            </button>
          ))}
        </div>

        <div className="bg-gray-900 border border-gray-700 rounded p-6 space-y-4">
          <div>
            <label className="text-xs text-gray-400 block mb-1">Fee Tier</label>
            <select value={fee} onChange={e => setFee(e.target.value)}
              className="w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm focus:border-green-400 outline-none">
              <option value="500">0.05%</option>
              <option value="3000">0.30%</option>
              <option value="10000">1.00%</option>
            </select>
          </div>

          {/* Tick range visual */}
          <div>
            <label className="text-xs text-gray-400 block mb-2">Price Range (Ticks)</label>
            <div className="relative h-8 bg-gray-800 rounded mb-3">
              <div className="absolute inset-y-0 bg-green-400 opacity-20 rounded"
                style={{ left: '10%', right: '10%' }} />
              <div className="absolute inset-y-0 w-0.5 bg-green-400" style={{ left: '10%' }} />
              <div className="absolute inset-y-0 w-0.5 bg-green-400" style={{ right: '10%' }} />
              <div className="absolute inset-y-0 w-0.5 bg-white opacity-50" style={{ left: '50%' }} />
              <span className="absolute text-xs text-green-400 top-1" style={{ left: '10%' }}>Low</span>
              <span className="absolute text-xs text-green-400 top-1" style={{ right: '10%' }}>High</span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs text-gray-500 block mb-1">Lower Tick</label>
                <input type="number" value={tickLower} onChange={e => setTickLower(e.target.value)}
                  className="w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm focus:border-green-400 outline-none" />
              </div>
              <div>
                <label className="text-xs text-gray-500 block mb-1">Upper Tick</label>
                <input type="number" value={tickUpper} onChange={e => setTickUpper(e.target.value)}
                  className="w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm focus:border-green-400 outline-none" />
              </div>
            </div>
          </div>

          <div>
            <label className="text-xs text-gray-400 block mb-1">
              {tab === 'mint' ? 'Liquidity Amount' : 'Amount to Remove'}
            </label>
            <div className="flex gap-2">
              <input type="number" value={amount} onChange={e => setAmount(e.target.value)}
                className="flex-1 bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm focus:border-green-400 outline-none" />
              {tab === 'burn' && (
                <div className="flex gap-1">
                  {['25', '50', '75', '100'].map(p => (
                    <button key={p} onClick={() => setAmount(p)}
                      className="bg-gray-700 hover:bg-gray-600 px-2 py-1 rounded text-xs">
                      {p}%
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          <StatusBadge status={status} error={txError} />

          <button
            onClick={tab === 'mint' ? handleMint : handleBurn}
            disabled={!address || status === 'pending' || status === 'approving' || status === 'confirming'}
            className="w-full bg-green-400 text-black font-bold py-3 rounded hover:bg-green-300 disabled:opacity-50">
            {status === 'approving' ? 'Approving…' :
             status === 'pending' ? 'Check MetaMask…' :
             status === 'confirming' ? 'Confirming…' :
             tab === 'mint' ? 'Add Liquidity' : 'Remove Liquidity'}
          </button>
        </div>
      </div>
    </main>
  )
}
