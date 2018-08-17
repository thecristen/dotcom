module.exports = function(casper, scenario, vp) {
  if (casper.exists("#plan_result_focus")) {
    casper.click("#plan_result_focus");
    casper.wait(500);
  }
}
