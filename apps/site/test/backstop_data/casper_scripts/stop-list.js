module.exports = function(casper, scenario, vp) {
  casper.click("[data-select-modal='origin']");
  casper.wait(500);
}
