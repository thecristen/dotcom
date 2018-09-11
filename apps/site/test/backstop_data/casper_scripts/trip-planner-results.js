module.exports = function(casper, scenario, vp) {
  if (casper.exists("#plan_result_focus")) {
    casper.click("#plan_result_focus");
    casper.click("#trip-plan-options-title");
    casper.wait(500);
  }
}
