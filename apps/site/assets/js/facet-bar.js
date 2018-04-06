import hogan from 'hogan.js';
import {FacetGroup} from "./facet-group"
import {FacetLocationGroup} from "./facet-location-group"

const facetGroupClasses = {FacetGroup, FacetLocationGroup};

export class FacetBar {
  constructor(container, search, facets) {
    this._container = document.getElementById(container);
    this._search = search;
    this._items = [];
    this._facetPrefixes = [];
    this._groups = {};
    if (this._container) {
      this._container.innerHTML = "";
      this._parseFacets(facets);
    }
  }

  updateCounts(facetResults) {
    Object.keys(this._items).forEach(queryId => {
      this._items[queryId].updateCounts(facetResults);
    });
  }

  _parseFacets(facets) {
    Object.keys(facets).forEach(queryId => {
      const facetData = facets[queryId].item;
      if (!facetData.prefix) {
        facetData.prefix = facets[queryId].facetName;
      }
      const groupClass = facetGroupClasses[facetData.cls || "FacetGroup"];
      this._items[queryId] = new groupClass(facetData, this);
      this._items[queryId].render(this._container, "c-facets__search-facet");
    });
  }

  update() {
    const queryIds = Object.keys(this._items);
    this._search.updateActiveQueries([]);
    queryIds.forEach(queryId => {
      this._items[queryId].modifySearch(this._search, queryId);
    });
    this._search.search();
  }
}
