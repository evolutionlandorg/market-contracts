all   :; source .env && dapp --use solc:0.4.24 build
flat  :; source .env && dapp --use solc:0.4.24 flat
clean :; dapp clean

.PHONY: all flat clean
