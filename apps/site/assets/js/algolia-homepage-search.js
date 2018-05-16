import { doWhenGoogleMapsIsReady} from './google-maps-loaded';
import hogan from "hogan.js";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo"
import { AlgoliaAutocomplete } from "./algolia-autocomplete"
import { featureIcon } from "./algolia-result";

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
    if (this._input) {
      this.init();
    }
  }

  init() {
    this._input.value = "";
    this._controller = new Algolia(AlgoliaHomepageSearch.INDICES, AlgoliaHomepageSearch.PARAMS);
    this._autocomplete = new AlgoliaAutocompleteWithGeo(AlgoliaHomepageSearch.SELECTORS,
                                                        Object.keys(AlgoliaHomepageSearch.INDICES),
                                                        {},
                                                        AlgoliaHomepageSearch.LOCATION_PARAMS,
                                                        this);
    this._autocomplete.renderFooterTemplate = this._renderFooterTemplate.bind(this);
    this._autocomplete.renderHeaderTemplate = this._renderHeaderTemplate.bind(this);
    this._autocomplete.showLocation = this._showLocation;
    this._controller.addWidget(this._autocomplete);
    this.addEventListeners();
  }

  _showLocation(latitude, longitude, address) {
    Turbolinks.visit(`/transit-near-me?latitude=${latitude}&longitude=${longitude}&location[address]=${address}`);
  }

  addEventListeners() {
    Object.keys(AlgoliaHomepageSearch.SHOWMOREPARAMS).forEach(key => {
      window.jQuery(document).on("click", `#show-more--${key}`, () => {
        this._onClickShowMore(key);
      });
    });
  }

  _renderHeaderTemplate(indexName) {
    const showMore = this._renderShowMoreTemplate(indexName);
    return `<div class="c-search-bar__results-header">${AlgoliaAutocomplete.DEFAULT_HEADERS[indexName]}${showMore}</div>`;
  }

  _renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return '<div class="c-search-result__google">' +
                document.getElementById("powered-by-google-logo").innerHTML +
             '</div>';
    }
    return "";
  }

  _renderShowMoreTemplate(indexName) {
    return `<span id="show-more--${indexName}" class="c-search-bar__autocomplete--show-more">Show more</span>`;
  }

  _onClickShowMore(indexName) {
    Turbolinks.visit(`/search?query=${this._input.value}&facets=${AlgoliaHomepageSearch.SHOWMOREPARAMS[indexName].facets}&showmore=${AlgoliaHomepageSearch.SHOWMOREPARAMS[indexName].showMore}`);
  }

  getParams() {
    return {
      from: "homepage-search",
      query: this._input.value
    };
  }
}

AlgoliaHomepageSearch.INDICES = {
  stops: {
    indexName: "stops",
    query: ""
  },
  routes: {
    indexName: "routes",
    query: ""
  },
  pagesdocuments: {
    indexName: "drupal",
    query: ""
  },
}

AlgoliaHomepageSearch.SELECTORS = {
  input: "homepage-search__input",
  container: "homepage-search__container",
  locationLoadingIndicator: "homepage-search__loading-indicator"
}

AlgoliaHomepageSearch.SHOWMOREPARAMS = {
  locations: {
    facets: "locations"
  },
  stops: {
    facets: "stops,facet-station,facet-stop",
    showMore: "stops"
  },
  routes: {
    facets: "lines-routes,subway,bus,commuter-rail,ferry",
    showMore: "routes"
  },
  pagesdocuments: {
    facets: "pages-parent,page,document",
    showMore: "pagesdocuments"
  },
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
  pagesdocuments: {
    hitsPerPage: 2,
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
}

AlgoliaHomepageSearch.LOCATION_PARAMS = {
  position: 3,
  hitLimit: 2
}
