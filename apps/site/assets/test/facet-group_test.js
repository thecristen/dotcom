import jsdom from "mocha-jsdom";
import { expect } from "chai";
import { FacetGroup } from "../../assets/js/facet-group";

describe("FacetGroup", () => {
  jsdom();

  function getFeatureIcon(feature) {
    return `<span id=${feature}></span>`
  }

  const items = {
    id: "lines-routes",
    name: "Lines and Routes",
    items: [
      {
        id: "subway",
        name: "Subway",
        facets: ["0", "1"],
        icon: getFeatureIcon("station")
      },
      {
        id: "commuter-rail",
        name: "Commuter Rail",
        facets: ["2"],
        icon: getFeatureIcon("commuter_rail")
      },
      {
        id: "bus",
        name: "Bus",
        facets: ["3"],
        icon: getFeatureIcon("bus")
      },
      {
        id: "ferry",
        name: "Ferry",
        facets: ["4"],
        icon: getFeatureIcon("ferry")
      }
    ]
  };

  describe("selectedFacetNames", function() {
    beforeEach(function() {
      document.body.innerHTML = `
        <div id="facet-group-container"></div>
      `;
      this.group = new FacetGroup(items, {});
      this.group.render(document.getElementById("facet-group-container"));
    });
    it("returns an empty list if no facets are selected", function() {
      expect(this.group.selectedFacetNames()).to.have.members([]);
    });

    it("returns a list of names if any items are checked", function() {
      this.group._item.check();
      expect(this.group.selectedFacetNames()).to.have.a.lengthOf(5);
    });
  });
});
