var HodlersDilemma = artifacts.require("HodlersDilemma");

module.exports = function(deployer) {
  deployer.deploy(HodlersDilemma, 200000000000000000, {value: 200000000000000000});
}