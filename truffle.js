var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "oak reward iron else various olympic quiz region addict develop sun bridge";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
      },
      host: "127.0.0.1",
      port: 7545,
      network_id: '*',
      gas: 6721975
    }
  },
  compilers: {
    solc: {
      version: "^0.4.25"
    }
  }
};