var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "letter allow maze torch giggle cotton culture honey dream win opera egg"; // 12 word mnemonic
var provider = new HDWalletProvider(mnemonic, "https://kovan.infura.io/sv2WF26MzGmjjevuh9hX ");

module.exports = {

    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*" // Match any network id
        },
        kovan: {
            provider: function() {
                return provider;
            },
            network_id: "*"
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
}