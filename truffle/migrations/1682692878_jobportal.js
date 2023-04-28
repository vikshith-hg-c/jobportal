const jobPortal = artifacts.require("jobPortal");
module.exports = function (deployer) {
  deployer.deploy(jobPortal);
};