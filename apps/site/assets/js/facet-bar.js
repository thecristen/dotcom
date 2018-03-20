import hogan from 'hogan.js';
import {FacetItem} from "./facet-item"

export class FacetBar {
  constructor(container, search, facets) {
    this._container = document.getElementById(container);
    this._search = search;
    this._items = [];
    this._facetPrefixes = [];
    this._groups = {};
    this._facetMap = {};
    if (this._container) {
      this._container.innerHTML = "";
      this._parseFacets(facets);
    }
  }

  updateCounts(facetResults) {
    Object.keys(this._facetMap).forEach(key => {
      let count = 0;
      key.split(",").forEach(facet => {
        if (facetResults[facet]) {
          count += facetResults[facet];
        }
      });
      this._facetMap[key].updateCount(count);
    });
  }

  _parseFacets(facets) {
    Object.keys(facets).forEach(queryId => {
      this._items[queryId] = [];
      facets[queryId].items.forEach(facetData => {
        if (!facetData.prefix) {
          facetData.prefix = facets[queryId].facetName;
        }
        this._items[queryId].push(new FacetItem(facetData, this));
      });
      this._items[queryId].forEach(facetItem => {
        facetItem.render(this._container, "c-facets__search-facet");
      });
    });
  }

  addToMap(facets, facetItem) {
    this._facetMap[facets] = facetItem;
  }

  getFacetsForQuery(queryId) {
    return [].concat.apply([], this._items[queryId].map(item => { return item.getActiveFacets() }));
  }

  shouldDisableQuery(queryId) {
    return this._items[queryId].map(item => { return item.allChildrenStatus(false) }).every(item => { return item == true });
  }

  update() {
    this._search.resetSearch();
    const queryIds = Object.keys(this._items);
    let toSearch = [];
    queryIds.forEach(queryId => {
      if (!this.shouldDisableQuery(queryId)) {
        toSearch.push(queryId);
        this._search.updateFacetFilters(queryId, this.getFacetsForQuery(queryId));
      }
    });
    this._search.updateActiveQueries(toSearch);
    this._search.search();
  }

  updateCount() {
    return true;
  }

  sumChildren() {
    return true;
  }
}
