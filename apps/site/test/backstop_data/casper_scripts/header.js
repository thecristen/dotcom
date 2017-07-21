module.exports = function(casper, scenario, vp) {
  // Header only shows up on desktop
  if (vp.name === 'xs' || vp.name === 'sm') {
    return;
  }
  var sel = '[data-target="' + scenario.selectors + '"]';
  casper.click(sel);
  casper.wait(1000);
}
