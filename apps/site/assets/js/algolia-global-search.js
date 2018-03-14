import { Algolia } from './algolia-search';

export function init() {
  const search = new AlgoliaGlobalSearch()
  document.addEventListener("turbolinks:load", search.init, {passive: true});
  return search;
}

export class AlgoliaGlobalSearch {
  constructor() {
    this.container = null;
    this.controller = null;
  }

  init() {
    this.container = document.getElementById(AlgoliaGlobalSearch.SELECTORS.searchBar);
    if (!this.container) {
      return false;
    }
    if (!this.controller) {
      this.controller = new Algolia(AlgoliaGlobalSearch.INDICES, AlgoliaGlobalSearch.PARAMS);
    }
    this.controller.search("");
  }
}

AlgoliaGlobalSearch.INDICES = ["routes", "stops", "drupal"];

AlgoliaGlobalSearch.PARAMS = {
  hitsPerPage: 5,
  facets: ["*"],
  facetFilters: [[]]
}

AlgoliaGlobalSearch.SELECTORS = {
  searchBar: "searchv2-input"
};
