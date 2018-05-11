module.exports = function(casper, scenario, vp) {
  var elements = ["#show-facets",
                  "#expansion-container-lines-routes",
                  "#expansion-container-stops",
                  "#expansion-container-pages-parent"
                 ]
  for(element in elements) {
    if (casper.exists(elements[element])) {
      casper.click(elements[element]);
    }
  }
  casper.wait(500);
}
