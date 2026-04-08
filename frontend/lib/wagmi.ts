import { createConfig, http } from 'wagmi'
import { foundry } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'

export const wagmiConfig = createConfig({
  chains: [foundry],
  connectors: [
    injected({
      target: 'metaMask',
    }),
  ],
  transports: {
    [foundry.id]: http('http://127.0.0.1:8545'),
  },
})
