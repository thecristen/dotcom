import { doWhenGoogleMapsIsReady} from './google-maps-loaded';
import * as QueryStringHelpers from "./query-string-helpers";
import hogan from "hogan.js";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo"
import { featureIcon } from "./algolia-result";

export const TEMPLATES = {
  locationResultHeader: hogan.compile(`
    <h5>
      Stations near "{{name}}..."
    </h5>
    `),
  locationResult: hogan.compile(`
    <div class="c-location-cards c-location-cards--background-white large-set c-search-bar__cards">
      {{#hits}}
        <a class="c-location-card" href="/stops/{{stop.id}}{{params}}">
          <div class="c-location-card__name">
            {{stop.name}}
          </div>
          <div class="c-location-card__distance">
            {{_rankingInfo.geoDistance}} mi
          </div>

          <div class="c-location-card__description">
          {{#routes}}
            <div class="c-location-card__transit-route-icon">
              {{{icon}}}
            </div>
            <div class="c-location-card__transit-route-name">
              {{display_name}}
            </div>
          {{/routes}}
          </div>
        </a>
      {{/hits}}
    </div>
  `),
}

export const METERS_PER_MILE = 1609.34;

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(() => { new AlgoliaStopSearch(); })
  });
}

export class AlgoliaStopSearch {
  constructor() {
    this._input = document.getElementById(AlgoliaStopSearch.SELECTORS.input);
    this._locationResultsHeader = document.getElementById(AlgoliaStopSearch.SELECTORS.locationResultsHeader);
    this._locationResultsBody = document.getElementById(AlgoliaStopSearch.SELECTORS.locationResultsBody);
    this._controller = null;
    this._autocomplete = null;
    this._goBtn = document.getElementById(AlgoliaStopSearch.SELECTORS.goBtn);
    this.bind();
    if (this._input) {
      this.init();
    }
  }

  bind() {
    this.onClickGoBtn = this.onClickGoBtn.bind(this);
  }

  init() {
    this._locationResultsHeader.innerHTML = "";
    this._locationResultsBody.innerHTML = "";
    this._input.value = "";
    this._addGoBtn();
    this._controller = new Algolia(AlgoliaStopSearch.INDICES, AlgoliaStopSearch.PARAMS);
    this._autocomplete = new AlgoliaAutocompleteWithGeo(AlgoliaStopSearch.SELECTORS,
                                                        Object.keys(AlgoliaStopSearch.INDICES),
                                                        AlgoliaStopSearch.HEADERS,
                                                        {position: 1, hitLimit: 5},
                                                        this);
    this._autocomplete.renderFooterTemplate = this._renderFooterTemplate.bind(this);
    this.addEventListeners();
    this._controller.addWidget(this._autocomplete);
  }

  addEventListeners() {
    this._goBtn.removeEventListener("click", this.onClickGoBtn);
    this._goBtn.addEventListener("click", this.onClickGoBtn);
  }

  _addGoBtn() {
    if (!this._goBtn) {
      this._goBtn = document.createElement("div");
      this._goBtn.id = AlgoliaStopSearch.SELECTORS.goBtn;
      this._goBtn.classList.add("c-search-bar__go-btn");
      this._goBtn.innerHTML = `GO`;
      this._input.parentNode.appendChild(this._goBtn);
    }
    return this._goBtn;
  }

  onClickGoBtn(ev) {
    this._autocomplete.clickHighlightedOrFirstResult();
  }

  onLocationResults(results) {
    if (results.stops) {
      results.stops.hits.map(hit => this._formatLocationResult(hit));
      results.stops.params = QueryStringHelpers.parseParams({
        from: "stop-search",
        query: this._input.value
      });
      this._locationResultsBody.innerHTML = TEMPLATES.locationResult.render(results.stops);
    }
  }

  _renderFooterTemplate(indexName) {
    if (indexName == "locations") {
      return AlgoliaResult.TEMPLATES.poweredByGoogleLogo.render({
        logo: document.getElementById("powered-by-google-logo").innerHTML
      });
    }
    return null;
  }

  changeLocationHeader(address) {
    this._locationResultsHeader.innerHTML = TEMPLATES.locationResultHeader.render({ name: address });
  }

  _formatLocationResult(hit) {
    hit.routes.map(route => {
      route.icon = featureIcon(route.icon);
    });
    hit._rankingInfo.geoDistance = (hit._rankingInfo.geoDistance / METERS_PER_MILE).toFixed(1);
  }

  getParams() {
    return {
      from: "stop-search",
      query: this._input.value
    };
  }
}

AlgoliaStopSearch.INDICES = {
  stops: {
    indexName: "stops",
    query: ""
  }
}

AlgoliaStopSearch.SELECTORS = {
  input: "stop-search__input",
  container: "stop-search__container",
  goBtn: "stop-search__go-btn",
  locationResultsBody: "stop-search__location-results--body",
  locationResultsHeader: "stop-search__location-results--header",
  locationLoadingIndicator: "stop-search__loading-indicator",
  resetButton: "stop-search__reset"
}

AlgoliaStopSearch.PARAMS = {
  stops: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[]]
  }
}

AlgoliaStopSearch.HEADERS = {
  stops: "MBTA Station Results",
  locations: "Location Results"
}
