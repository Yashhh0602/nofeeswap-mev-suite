'use client'
import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseAbi, keccak256, encodeAbiParameters } from 'viem'
import { CONTRACTS, TOKEN0_SYMBOL, TOKEN1_SYMBOL } from '@/lib/contracts'
import Link from 'next/link'

const ABI = parseAbi([
  'function initialize(bytes32 poolId, uint160 sqrtPriceX96, bytes calldata kernel, bytes calldata hookData) external returns (int24)',
])

function priceToSqrtX96(price: number): bigint {
  const sqrt = Math.sqrt(price)
  return BigInt(Math.floor(sqrt * 2 ** 96))
}

function computePoolId(token0: string, token1: string, fee: number): `0x${string}` {
  const [t0, t1] = [token0, token1].sort()
  return keccak256(encodeAbiParameters(
    [{ type: 'address' }, { type: 'address' }, { type: 'uint24' }],
    [t0 as `0x${string}`, t1 as `0x${string}`, fee]
  ))
}

const MOCK_KERNEL = '0x80008000800000000000000000000000000000000000000000000000000000000000000000000000'

interface Point { x: number; y: number }

function KernelEditor({ points, onChange }: { points: Point[], onChange: (p: Point[]) => void }) {
  const W = 400, H = 160, P = 24
  const toSvg = (pt: Point) => ({ cx: P + pt.x * (W - 2*P), cy: P + (1 - pt.y) * (H - 2*P) })
  const fromSvg = (cx: number, cy: number): Point => ({
    x: Math.max(0, Math.min(1, (cx - P) / (W - 2*P))),
    y: Math.max(0, Math.min(1, 1 - (cy - P) / (H - 2*P)))
  })
  const sorted = [...points].sort((a, b) => a.x - b.x)
  const pathD = sorted.length > 0
    ? 'M ' + [{ cx: P, cy: P + (H-2*P) }, ...sorted.map(toSvg), { cx: W-P, cy: toSvg(sorted[sorted.length-1]).cy }]
        .map(p => `${p.cx},${p.cy}`).join(' L ')
    : ''

  const handleClick = (e: React.MouseEvent<SVGSVGElement>) => {
    if ((e.target as SVGElement).tagName === 'circle') return
    const rect = e.currentTarget.getBoundingClientRect()
    const cx = (e.clientX - rect.left) * (W / rect.width)
    const cy = (e.clientY - rect.top) * (H / rect.height)
    onChange([...points, fromSvg(cx, cy)])
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-2">
        <span className="text-xs text-gray-400">Click to add points · Right-click to remove</span>
        <div className="flex gap-2">
          <button onClick={() => onChange([{x:0.5,y:1}])} className="text-xs bg-gray-700 px-2 py-1 rounded">Concentrated</button>
          <button onClick={() => onChange([{x:0.25,y:0.5},{x:0.75,y:0.5}])} className="text-xs bg-gray-700 px-2 py-1 rounded">Uniform</button>
          <button onClick={() => onChange([])} className="text-xs bg-gray-700 px-2 py-1 rounded">Clear</button>
        </div>
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full border border-gray-700 rounded bg-gray-950 cursor-crosshair"
        onClick={handleClick}>
        <line x1={P} y1={P} x2={P} y2={H-P} stroke="#374151" />
        <line x1={P} y1={H-P} x2={W-P} y2={H-P} stroke="#374151" />
        {[0.25,0.5,0.75].map(t => (
          <line key={t} x1={P + t*(W-2*P)} y1={P} x2={P + t*(W-2*P)} y2={H-P} stroke="#1f2937" strokeDasharray="3,3" />
        ))}
        {pathD && <path d={pathD} fill="rgba(74,222,128,0.1)" stroke="#4ade80" strokeWidth={1.5} />}
        {points.map((pt, i) => {
          const { cx, cy } = toSvg(pt)
          return (
            <circle key={i} cx={cx} cy={cy} r={6} fill="#4ade80" stroke="#000" strokeWidth={1}
              style={{ cursor: 'grab' }}
              onContextMenu={e => { e.preventDefault(); onChange(points.filter((_,j) => j !== i)) }} />
          )
        })}
        <text x={P} y={H-4} fill="#4b5563" fontSize={8}>price →</text>
        <text x={4} y={P + (H-2*P)/2} fill="#4b5563" fontSize={8} transform={`rotate(-90,8,${P+(H-2*P)/2})`}>liq</text>
      </svg>
    </div>
  )
}

export default function PoolPage() {
  const { address } = useAccount()
  const [token0] = useState(CONTRACTS.token0)
  const [token1] = useState(CONTRACTS.token1)
  const [fee, setFee] = useState('3000')
  const [price, setPrice] = useState('1.0')
  const [useMock, setUseMock] = useState(true)
  const [points, setPoints] = useState<Point[]>([{x:0.3,y:0.8},{x:0.5,y:1},{x:0.7,y:0.8}])

  const { writeContract, data: hash, error, isPending } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const poolId = computePoolId(token0, token1, parseInt(fee))

  const handleInit = () => {
    const sqrtPriceX96 = priceToSqrtX96(parseFloat(price))
    writeContract({
      address: CONTRACTS.nofeeswap as `0x${string}`,
      abi: ABI,
      functionName: 'initialize',
      args: [poolId, sqrtPriceX96, MOCK_KERNEL as `0x${string}`, '0x'],
    })
  }

  return (
    <main className="min-h-screen bg-black text-white p-8">
      <div className="max-w-3xl mx-auto">
        <Link href="/" className="text-gray-500 text-sm mb-6 block">← Back</Link>
        <h1 className="text-3xl font-bold mb-2">Initialize Pool</h1>
        <p className="text-gray-400 mb-8">Create a new NoFeeSwap liquidity pool</p>

        <div className="grid grid-cols-2 gap-6">
          <div className="space-y-4">
            <div className="bg-gray-900 border border-gray-800 rounded p-3">
              <p className="text-xs text-gray-500 mb-1">Token 0</p>
              <p className="font-mono text-xs text-green-400">{token0}</p>
              <p className="text-xs text-gray-400 mt-1">{TOKEN0_SYMBOL}</p>
            </div>
            <div className="bg-gray-900 border border-gray-800 rounded p-3">
              <p className="text-xs text-gray-500 mb-1">Token 1</p>
              <p className="font-mono text-xs text-green-400">{token1}</p>
              <p className="text-xs text-gray-400 mt-1">{TOKEN1_SYMBOL}</p>
            </div>

            <div>
              <label className="text-xs text-gray-400 block mb-1">Fee Tier</label>
              <select value={fee} onChange={e => setFee(e.target.value)}
                className="w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm focus:border-green-400 outline-none">
                <option value="500">0.05% — 500</option>
                <option value="3000">0.30% — 3000</option>
                <option value="10000">1.00% — 10000</option>
              </select>
            </div>

            <div>
              <label className="text-xs text-gray-400 block mb-1">Initial Price (TK1 per TK0)</label>
              <input type="number" value={price} onChange={e => setPrice(e.target.value)}
                className="w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm focus:border-green-400 outline-none" />
            </div>

            <div className="bg-gray-900 border border-gray-800 rounded p-3">
              <p className="text-xs text-gray-500 mb-1">Pool ID (computed)</p>
              <p className="font-mono text-xs text-green-400 break-all">{poolId}</p>
            </div>

            <div className="flex gap-2">
              <button onClick={() => setUseMock(true)}
                className={`flex-1 py-2 rounded text-sm font-bold ${useMock ? 'bg-green-400 text-black' : 'bg-gray-800 text-gray-300'}`}>
                Mock Kernel
              </button>
              <button onClick={() => setUseMock(false)}
                className={`flex-1 py-2 rounded text-sm font-bold ${!useMock ? 'bg-green-400 text-black' : 'bg-gray-800 text-gray-300'}`}>
                Visual Editor
              </button>
            </div>

            <button onClick={handleInit} disabled={!address || isPending || isConfirming}
              className="w-full bg-green-400 text-black font-bold py-3 rounded hover:bg-green-300 disabled:opacity-50">
              {isPending ? 'Check MetaMask…' : isConfirming ? 'Confirming…' : 'Initialize Pool'}
            </button>

            {isSuccess && (
              <div className="bg-green-900 border border-green-500 rounded p-3 text-sm text-green-200">
                ✅ Pool initialized! Tx: {hash?.slice(0,20)}…
              </div>
            )}
            {error && (
              <div className="bg-red-900 border border-red-500 rounded p-3 text-sm text-red-200">
                ❌ {error.message.slice(0, 120)}
              </div>
            )}
          </div>

          <div className="space-y-4">
            <div className="bg-gray-900 border border-gray-800 rounded p-4">
              <h3 className="font-bold mb-3 text-sm">Kernel — Liquidity Shape</h3>
              {useMock ? (
                <div className="text-center py-8 border border-dashed border-gray-700 rounded">
                  <p className="text-gray-400 text-sm">Mock kernel active</p>
                  <p className="text-green-400 text-xs mt-2 font-mono">[(2¹⁵, 2¹⁵), (2¹⁵, 0)]</p>
                  <p className="text-gray-600 text-xs mt-1">Uniform liquidity distribution</p>
                </div>
              ) : (
                <KernelEditor points={points} onChange={setPoints} />
              )}
            </div>
            <div className="bg-gray-900 border border-gray-800 rounded p-4 text-xs text-gray-400 space-y-1">
              <p className="font-bold text-gray-300 mb-2">How it works</p>
              <p>1. Token pair + fee tier → hashed into poolId</p>
              <p>2. Price → encoded as sqrtPriceX96 (Q64.96)</p>
              <p>3. Kernel defines liquidity distribution shape</p>
              <p>4. Calls initialize() on NoFeeSwap core contract</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}
