import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import {FacetItem} from '../../assets/js/facet-item.js'
import {FacetBar} from '../../assets/js/facet-bar.js'

function getFeatureIcon(feature) {
  return `<span id=${feature}></span>`
}

describe('facet', function() {
  let $;
  jsdom();

  const testData = {
    routes: {
      indexName: "routes",
      facetName: "routes",
      items: [
        {
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
            },
          ]
        },
      ]
    },
    stops: {
      indexName: "stops",
      facetName: "stop",
      items: [
        {
          id: "stops",
          name: "Stops",
          prefix: "stop",
          items: [
            {
              id: "stop-subway",
              name: "Subway",
              facets: ["subway"],
              icon: getFeatureIcon("station")
            }
          ]
        }
      ]
    }
  }

  const search = {};
  const changeAllCheckboxes = (state) => {
    Object.keys(checkBoxes).forEach(key => {
      $(checkBoxes[key]).prop("checked", state);
    });
  };

  const checkBoxes = {
    parent: "#checkbox-item-lines-routes",
    bus: "#checkbox-item-bus",
    cr: "#checkbox-item-commuter-rail",
    ferry: "#checkbox-item-ferry",
    subway: "#checkbox-item-subway",
  };

  beforeEach(function() {
    $ = jsdom.rerequire('jquery');
    $('body').empty();
    $('body').append('<div id="test"></div>');
    this.facetBar = new FacetBar("test", search, testData);
    this.testFacetItem = this.facetBar._items["routes"][0];
    changeAllCheckboxes(false);
  });

  describe("item event handlers", function() {
    it('makes 7 checkboxes, one for each item', function() {
      assert.equal($("input[type='checkbox']").length, 7);
    });

    it('unchecks all children when unchecking the parent box', function() {
      changeAllCheckboxes(true);
      assert.equal($("input[type='checkbox']:checked").length, 5);
      $(checkBoxes.parent).trigger("click");
      assert.equal($("input[type='checkbox']:checked").length, 0);
    });

    it('checks all children when checking the parent box', function() {
      assert.equal($("input[type='checkbox']:checked").length, 0);
      $(checkBoxes.parent).trigger("click");
      assert.equal($("input[type='checkbox']:checked").length, 5);
    });

    it('unchecks the parent if any child is unchecked', function() {
      changeAllCheckboxes(true);
      $(checkBoxes.bus).trigger("click");
      assert.equal($(checkBoxes.parent).prop("checked"), false);
      assert.equal($(checkBoxes.bus).prop("checked"), false);
    });

    it('checks the parent if all children are checked', function() {
      assert.equal($(checkBoxes.parent).prop("checked"), false);
      $(checkBoxes.bus).trigger("click");
      $(checkBoxes.cr).trigger("click");
      $(checkBoxes.subway).trigger("click");
      assert.equal($(checkBoxes.parent).prop("checked"), false);
      $(checkBoxes.ferry).trigger("click");
      assert.equal($(checkBoxes.parent).prop("checked"), true);
    });
  });

  describe("item", function() {
    it('returns a flattened list of active facets', function() {
      changeAllCheckboxes(true);
      assert.deepEqual(this.testFacetItem.getActiveFacets(), ["routes:0", "routes:1", "routes:2", "routes:3", "routes:4"]);
    });
  });

  describe("bar", function() {
    it('properly parses facet data into items', function() {
      assert.deepEqual(Object.keys(this.facetBar._items), ["routes", "stops"]);
      assert.equal(this.facetBar._items["routes"][0]._id, "lines-routes");
      assert.deepEqual(this.facetBar._items["routes"][0]._children.map(item => { return item._id }), ["subway", "commuter-rail", "bus", "ferry"]);
      assert.equal(this.facetBar._items["stops"][0]._id, "stops");
      assert.deepEqual(this.facetBar._items["stops"][0]._children.map(item => { return item._id }), ["stop-subway"]);
    });

    it('updates a map to keep track of which facets should be updated', function() {
      assert.deepEqual(Object.keys(this.facetBar._facetMap), ['routes:0,routes:1', 'routes:2', 'routes:3', 'routes:4', 'stop:subway']);
    });

    it('updates results for facet items in the facet map', function() {
      const results = {
        "routes:0": 1,
        "routes:1": 2,
        "routes:2": 3,
        "routes:3": 4,
        "routes:4": 5,
        "stop:subway": 10
      };
      this.facetBar.updateCounts(results);
      const routesFacet = this.facetBar._items["routes"][0];
      const stopsFacet = this.facetBar._items["stops"][0];
      assert(routesFacet._count, results["routes:0"] +
                                 results["routes:1"] +
                                 results["routes:2"] +
                                 results["routes:3"] +
                                 results["routes:4"]);
      assert(stopsFacet._count, results["stop:subway"]);
    });

    it('disables indexes if a facet tree is completely unchecked', function() {
      $(checkBoxes.cr).prop("checked", true);
      assert.equal(this.facetBar.shouldDisableIndex("routes"), false);
      assert.equal(this.facetBar.shouldDisableIndex("stops"), true);
    });
  });
});
