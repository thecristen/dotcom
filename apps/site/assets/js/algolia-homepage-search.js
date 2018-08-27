import { doWhenGoogleMapsIsReady} from './google-maps-loaded';
import { Algolia } from "./algolia-search";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo";
import { animatePlaceholder } from "./animated-placeholder";
import { placeholders } from "./search-placeholders";

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => { new AlgoliaHomepageSearch(); })
  });
}

export class AlgoliaHomepageSearch {
  constructor() {
    this._input = document.getElementById(AlgoliaHomepageSearch.SELECTORS.input);
    this._controller = null;
    this._autocomplete = null;
    this.bind();
    if (this._input) {
      this.init();
    }
  }

  init() {
    this._input.value = "";
    this._controller = new Algolia(AlgoliaHomepageSearch.INDICES, AlgoliaHomepageSearch.PARAMS);
    this._autocomplete = new AlgoliaAutocompleteWithGeo("homepage-autocomplete",
                                                        AlgoliaHomepageSearch.SELECTORS,
                                                        Object.keys(AlgoliaHomepageSearch.INDICES),
                                                        AlgoliaHomepageSearch.LOCATION_PARAMS,
                                                        this);
    this._autocomplete.renderFooterTemplate = this._renderFooterTemplate;
    this._controller.addWidget(this._autocomplete);
    animatePlaceholder(AlgoliaHomepageSearch.SELECTORS.input, placeholders);
  }

  bind() {
    this._renderFooterTemplate = this._renderFooterTemplate.bind(this);
  }

  _renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return '<div class="c-search-result__google">' +
                document.getElementById("powered-by-google-logo").innerHTML +
             '</div>';
    }
    return "";
  }

  getParams() {
    return {
      from: "homepage-search",
      query: this._input.value
    };
  }
}

AlgoliaHomepageSearch.INDICES = {
  routes: {
    indexName: "routes",
    query: ""
  },
  stops: {
    indexName: "stops",
    query: ""
  },
  pages: {
    indexName: "drupal",
    query: ""
  },
}

AlgoliaHomepageSearch.SELECTORS = {
  input: "homepage-search__input",
  container: "homepage-search__container",
  locationLoadingIndicator: "homepage-search__loading-indicator",
  resetButton: "homepage-search__reset"
}

AlgoliaHomepageSearch.PARAMS = {
  stops: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[]]
  },
  routes: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[]]
  },
  pages: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[
      "_content_type:page",
      "_content_type:search_result",
      "_content_type:landing_page",
      "_content_type:person",
      "_content_type:project",
      "_content_type:project_update"
    ]]
  },
}

AlgoliaHomepageSearch.LOCATION_PARAMS = {
  position: 3,
  hitLimit: 2
}
