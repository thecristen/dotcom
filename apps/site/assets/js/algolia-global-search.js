import { doWhenGoogleMapsIsReady } from './google-maps-loaded';
import { Algolia } from './algolia-search';
import { AlgoliaWithGeo } from './algolia-search-with-geo';
import { AlgoliaFacets } from './algolia-facets';
import { AlgoliaResults } from './algolia-results';

export function init() {
  const search = new AlgoliaGlobalSearch();
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => {
      search.init();
    })
  }, {passive: true});
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
      this.controller = new AlgoliaWithGeo(AlgoliaGlobalSearch.INITIAL_QUERIES, AlgoliaGlobalSearch.DEFAULT_PARAMS, AlgoliaGlobalSearch.LATLNGBOUNDS);
    }

    this.container.value = "";
    this.controller.addWidget(new AlgoliaFacets(AlgoliaGlobalSearch.SELECTORS, this.controller));
    this.controller.addWidget(new AlgoliaResults(AlgoliaGlobalSearch.SELECTORS.resultsContainer, this));
    this.container.addEventListener("input", () => {
      this.controller.search({query: this.container.value});
    });
  }

  onClickShowMore(group) {
    this.controller.addPage(group);
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

AlgoliaGlobalSearch.LATLNGBOUNDS = {
  west: 41.3193,
  north: -71.9380,
  east: 42.8266,
  south: -69.6189
}
