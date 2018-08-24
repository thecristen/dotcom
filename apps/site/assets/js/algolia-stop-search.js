import { doWhenGoogleMapsIsReady} from './google-maps-loaded';
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo"

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => { new AlgoliaStopSearch(); })
  });
}

export class AlgoliaStopSearch {
  constructor() {
    this.input = document.getElementById(AlgoliaStopSearch.SELECTORS.input);
    this.controller = null;
    this.autocomplete = null;
    this.goBtn = document.getElementById(AlgoliaStopSearch.SELECTORS.goBtn);
    this.bind();
    if (this.input) {
      this.init();
    }
  }

  bind() {
    this.onClickGoBtn = this.onClickGoBtn.bind(this);
  }

  init() {
    this.input.value = "";
    this.controller = new Algolia(AlgoliaStopSearch.INDICES, AlgoliaStopSearch.PARAMS);
    this.autocomplete = new AlgoliaAutocompleteWithGeo("stops-page-search",
                                                        AlgoliaStopSearch.SELECTORS,
                                                        Object.keys(AlgoliaStopSearch.INDICES),
                                                        AlgoliaStopSearch.HEADERS,
                                                        {position: 1, hitLimit: 5},
                                                        this);
    this.autocomplete.renderFooterTemplate = this.renderFooterTemplate.bind(this);
    this.addEventListeners();
    this.controller.addWidget(this.autocomplete);
  }

  addEventListeners() {
    this.goBtn.removeEventListener("click", this.onClickGoBtn);
    this.goBtn.addEventListener("click", this.onClickGoBtn);
  }

  onClickGoBtn() {
    this.autocomplete.clickHighlightedOrFirstResult();
  }

  renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return AlgoliaResult.TEMPLATES.poweredByGoogleLogo.render({
        logo: document.getElementById("powered-by-google-logo").innerHTML
      });
    }
    return null;
  }

  getParams() {
    return {
      from: "stop-search",
      query: this.input.value
    };
  }
}

AlgoliaStopSearch.INDICES = {
  stops: {
    indexName: "stops",
    query: ""
  }
};

AlgoliaStopSearch.SELECTORS = {
  input: "stop-search__input",
  container: "stop-search__container",
  goBtn: "stop-search__input-go-btn",
  locationLoadingIndicator: "stop-search__loading-indicator",
  resetButton: "stop-search__reset"
};

AlgoliaStopSearch.PARAMS = {
  stops: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[]]
  }
};

AlgoliaStopSearch.HEADERS = {
  stops: "MBTA Station Results",
  locations: "Location Results"
};
