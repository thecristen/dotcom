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
    this._facetsWidget = null;
    this._bind();
  }

  _bind() {
    this.reset = this.reset.bind(this);
    this.onInput = this.onInput.bind(this);
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

    this._facetsWidget = new AlgoliaFacets(AlgoliaGlobalSearch.SELECTORS, this.controller);
    this.controller.addWidget(this._facetsWidget);

    this._resultsWidget = new AlgoliaResults(AlgoliaGlobalSearch.SELECTORS.resultsContainer, this);
    this.controller.addWidget(this._resultsWidget);

    this.addEventListeners();
  }

  addEventListeners() {
    this.container.removeEventListener("input", this.onInput);
    this.container.addEventListener("input", this.onInput);

    const clearButton = document.getElementById(AlgoliaGlobalSearch.SELECTORS.clearSearchButton);
    if (clearButton) {
      clearButton.removeEventListener("click", this.reset);
      clearButton.addEventListener("click", this.reset);
    }
  }

  reset(ev) {
    this.container.value = "";
    this._facetsWidget.reset();
    this._resultsWidget.reset();
    window.jQuery(this.container).focus();
  }

  onInput(ev) {
    this.controller.search({query: this.container.value});
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
  searchBar: "search-input",
  facetsContainer: "search-facets-container",
  resultsContainer: "search-results-container",
  closeModalButton: "close-facets-modal",
  showFacetsButton: "show-facets",
  clearSearchButton: "search-clear-icon",
};

AlgoliaGlobalSearch.LATLNGBOUNDS = {
  west: 41.3193,
  north: -71.9380,
  east: 42.8266,
  south: -69.6189
}
