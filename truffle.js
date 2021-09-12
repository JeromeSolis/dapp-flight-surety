var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "tennis notice reflect salon royal rhythm rich supply culture isolate century dog";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
      },
      network_id: '*',
      // gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.4.25"
    }
  }
};