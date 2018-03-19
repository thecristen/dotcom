import { Algolia } from './algolia-search';
import { AlgoliaFacets } from './algolia-facets';
import { AlgoliaResults } from './algolia-results';

export function init() {
  const search = new AlgoliaGlobalSearch()
  document.addEventListener("turbolinks:load", search.init.bind(search), {passive: true});
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

    this.controller.addWidget(new AlgoliaFacets(AlgoliaGlobalSearch.INDICES, AlgoliaGlobalSearch.SELECTORS, this.controller));
    this.controller.addWidget(new AlgoliaResults(AlgoliaGlobalSearch.SELECTORS.resultsContainer));
    this.container.addEventListener("input", () => {
      this.controller.search(this.container.value);
    });
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
  searchBar: "searchv2-input",
  facetsContainer: "searchv2-facets-container",
  resultsContainer: "searchv2-results-container",
  closeModalButton: "close-facets-modal",
  showFacetsButton: "show-facets",
};
