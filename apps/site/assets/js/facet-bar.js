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
    Object.keys(facets).forEach(index => {
      this._items[index] = [];
      facets[index].items.forEach(facetData => {
        if (!facetData.prefix) {
          facetData.prefix = facets[index].facetName;
        }
        this._items[index].push(new FacetItem(facetData, this));
      });
      this._items[index].forEach(facetItem => {
        facetItem.render(this._container, "c-facets__search-facet");
      });
    });
  }

  addToMap(facets, facetItem) {
    this._facetMap[facets] = facetItem;
  }

  getFacetsForIndex(index) {
    return [].concat.apply([], this._items[index].map(item => { return item.getActiveFacets() }));
  }

  shouldDisableIndex(index) {
    return this._items[index].map(item => { return item.allChildrenStatus(false) }).every(item => { return item == true });
  }

  update() {
    this._search.resetSearch();
    const indexes = Object.keys(this._items);
    let toSearch = []
      indexes.forEach(index => {
        if (!this.shouldDisableIndex(index)) {
          toSearch.push(index);
          this._search.updateFacetFilters(index, this.getFacetsForIndex(index));
        }
      });
    this._search.updateIndices(toSearch);
    this._search.search();
  }

  updateCount() {
    return true;
  }

  sumChildren() {
    return true;
  }
}
