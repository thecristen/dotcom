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
      this.controller = new Algolia(AlgoliaGlobalSearch.INITIAL_QUERIES, AlgoliaGlobalSearch.DEFAULT_PARAMS);
    }

    this.controller.addWidget(new AlgoliaFacets(AlgoliaGlobalSearch.SELECTORS, this.controller));
    this.controller.addWidget(new AlgoliaResults(AlgoliaGlobalSearch.SELECTORS.resultsContainer));
    this.container.addEventListener("input", () => {
      this.controller.search(this.container.value);
    });
    this.controller.search("");
  }
}

AlgoliaGlobalSearch.INITIAL_QUERIES = {
  routes: {
    indexName: "routes",
    query: ""
  },
  stops: {
    indexName: "stops",
    query: ""
  },
  pagesdocuments: {
    indexName: "drupal",
    query: ""
  },
  events: {
    indexName: "drupal",
    query: ""
  },
  news: {
    indexName: "drupal",
    query: ""
  },
}

AlgoliaGlobalSearch.DEFAULT_PARAMS = {
  routes: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[]]
  },
  stops: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[]]
  },
  pagesdocuments: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[
      "_content_type:page",
      "_content_type:search_result",
      "_content_type:landing_page",
      "_content_type:person",
      "_content_type:project",
      "_content_type:project_update",
      "search_api_datasource:entity:file"
    ]]
  },
  events: {
    hitsPerPage: 5,
    facets: ["_content_type"],
    facetFilters: [[
      "_content_type:event",
    ]]
  },
  news: {
    hitsPerPage: 5,
    facets: ["_content_type"],
    facetFilters: [[
      "_content_type:news_entry",
    ]]
  },
}

AlgoliaGlobalSearch.SELECTORS = {
  searchBar: "searchv2-input",
  facetsContainer: "searchv2-facets-container",
  resultsContainer: "searchv2-results-container",
  closeModalButton: "close-facets-modal",
  showFacetsButton: "show-facets",
};
