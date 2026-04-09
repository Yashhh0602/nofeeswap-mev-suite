brownie test -n auto --network hardhat
echidna ./echidna/IntegralTest.sol --contract IntegralTest --config ./echidna/echidna.config.Integral.yml
echidna ./echidna/SearchIncomingTest.sol --contract SearchIncomingTest --config ./echidna/echidna.config.SearchIncoming.yml
echidna ./echidna/SearchOutgoingTest.sol --contract SearchOutgoingTest --config ./echidna/echidna.config.SearchOutgoing.yml
echidna ./echidna/SearchOvershootTest.sol --contract SearchOvershootTest --config ./echidna/echidna.config.SearchOvershoot.yml