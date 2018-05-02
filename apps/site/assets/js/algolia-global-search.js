import { doWhenGoogleMapsIsReady } from './google-maps-loaded';
import { AlgoliaWithGeo } from './algolia-search-with-geo'; import { AlgoliaFacets } from './algolia-facets'; import { AlgoliaResults } from './algolia-results'; import * as QueryStringHelpers from "./query-string-helpers"; export function init() { const search = new AlgoliaGlobalSearch();
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
    this._showMoreList = [];
    this._queryParams = {};
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

    this._facetsWidget = new AlgoliaFacets(AlgoliaGlobalSearch.SELECTORS, this.controller, this);
    this._facetsWidget.reset();
    this.controller.addWidget(this._facetsWidget);
    this.loadState(window.location.search);

    this._resultsWidget = new AlgoliaResults(AlgoliaGlobalSearch.SELECTORS.resultsContainer, this);
    this.controller.addWidget(this._resultsWidget);

    this.addEventListeners();
    this.controller.search({query: this.container.value});
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

  loadState(query) {
    this._queryParams = QueryStringHelpers.parseQuery(query);
    this.container.value = this._queryParams["query"] || "";
    const facetState = this._queryParams["facets"] || "";
    this._facetsWidget.loadState(facetState.split(","));
    if (facetState != "") {
      this.controller.enableLocationSearch(facetState.includes("locations"));
    }
    const showMoreState = this._queryParams["showmore"] || "";
    if (showMoreState != "") {
      showMoreState.split(",").forEach(group => {
        this.onClickShowMore(group);
      });
    }
  }

  reset(ev) {
    this.container.value = "";
    this.controller.reset();
    this._queryParams = {};
    this.updateHistory();
    window.jQuery(this.container).focus();
  }

  updateHistory() {
    this._queryParams["query"] = this.container.value;
    this._queryParams["facets"] = this._facetsWidget.selectedFacetNames().join(",");
    this._queryParams["showmore"] = this._showMoreList.join(",");
    window.history.replaceState(window.history.state, "", window.location.pathname + QueryStringHelpers.parseParams(this._queryParams));
  }

  onInput(ev) {
    this.controller.search({query: this.container.value});
    this.updateHistory();
  }

  onClickShowMore(group) {
    this.controller.addPage(group);
    this._showMoreList.push(group);
    this.updateHistory();
  }

  getParams() {
    return {
      from: "global-search",
      query: this.container.value,
      facets: this._facetsWidget.selectedFacetNames().join(",")
    }
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
