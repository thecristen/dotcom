module.exports = function(casper, scenario, vp) {
  if (casper.exists("[data-select-modal='origin']")) {
    casper.click("[data-select-modal='origin']");
    casper.wait(500);
  }
}
