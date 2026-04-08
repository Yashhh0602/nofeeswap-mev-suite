'use client'
import { useState, useEffect } from 'react'
import { useAccount, useConnect, useDisconnect, useBalance, useSwitchChain } from 'wagmi'
import { foundry } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'
import { CONTRACTS, TOKEN0_SYMBOL, TOKEN1_SYMBOL } from '@/lib/contracts'
import Link from 'next/link'

export default function Home() {
  const { address, isConnected, chainId } = useAccount()
  const { connect, error, isPending } = useConnect()
  const { disconnect } = useDisconnect()
  const { switchChain } = useSwitchChain()
  const [hasEthereum, setHasEthereum] = useState(false)

  useEffect(() => {
    setHasEthereum(!!window.ethereum)
  }, [])

  // Auto switch to Anvil if on wrong network
  useEffect(() => {
    if (isConnected && chainId !== foundry.id) {
      switchChain({ chainId: foundry.id })
    }
  }, [isConnected, chainId, switchChain])

  const { data: bal0 } = useBalance({ address, token: CONTRACTS.token0 as `0x${string}` })
  const { data: bal1 } = useBalance({ address, token: CONTRACTS.token1 as `0x${string}` })

  const handleConnect = async () => {
    connect({ connector: injected() })
  }

  const wrongNetwork = isConnected && chainId !== foundry.id

  return (
    <main className="min-h-screen bg-black text-white p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">NoFeeSwap</h1>
        <p className="text-gray-400 mb-8">Local dev interface · Anvil</p>

        {error && (
          <div className="bg-red-900 border border-red-500 rounded p-3 mb-4 text-sm text-red-200">
            Error: {error.message}
          </div>
        )}

        {wrongNetwork && (
          <div className="bg-yellow-900 border border-yellow-500 rounded p-3 mb-4 text-sm text-yellow-200">
            ⚠️ Wrong network detected. Switching to Anvil Local...
            <button onClick={() => switchChain({ chainId: foundry.id })}
              className="ml-3 underline font-bold">Switch now</button>
          </div>
        )}

        {!isConnected ? (
          <div>
            <button
              onClick={handleConnect}
              disabled={isPending}
              className="bg-green-400 text-black font-bold px-6 py-3 rounded hover:bg-green-300 disabled:opacity-50"
            >
              {isPending ? 'Connecting...' : 'Connect MetaMask'}
            </button>
            <p className="text-gray-500 text-sm mt-3">
              MetaMask detected: {hasEthereum ? '✅ Yes' : '❌ No'}
            </p>
          </div>
        ) : (
          <div>
            <div className="bg-gray-900 border border-gray-700 rounded p-4 mb-6">
              <p className="text-sm text-gray-400 mb-1">Connected · Chain ID: {chainId}</p>
              <p className="font-mono text-green-400 text-sm">{address}</p>
              <div className="flex gap-8 mt-3">
                <div>
                  <p className="text-xs text-gray-500">{TOKEN0_SYMBOL}</p>
                  <p className="text-lg font-bold">{bal0?.formatted ?? '0'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">{TOKEN1_SYMBOL}</p>
                  <p className="text-lg font-bold">{bal1?.formatted ?? '0'}</p>
                </div>
              </div>
              <button onClick={() => disconnect()} className="mt-3 text-xs text-gray-500 underline">
                Disconnect
              </button>
            </div>

            <div className="grid grid-cols-3 gap-4">
              {[
                { href: '/pool', title: 'Initialize Pool', desc: 'Create a new trading pool' },
                { href: '/liquidity', title: 'Manage Liquidity', desc: 'Add or remove liquidity' },
                { href: '/swap', title: 'Swap Tokens', desc: 'Trade TK0 ↔ TK1' },
              ].map(({ href, title, desc }) => (
                <Link key={href} href={href}
                  className="bg-gray-900 border border-gray-700 hover:border-green-400 rounded p-5 transition-colors block">
                  <h2 className="font-bold mb-1">{title}</h2>
                  <p className="text-sm text-gray-400">{desc}</p>
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>
    </main>
  )
}
