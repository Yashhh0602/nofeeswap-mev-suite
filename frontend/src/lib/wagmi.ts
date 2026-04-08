import { createConfig, http } from 'wagmi'
import { foundry } from 'wagmi/chains'

export const wagmiConfig = createConfig({
  chains: [foundry],
  transports: {
    [foundry.id]: http('http://127.0.0.1:8545'),
  },
})
