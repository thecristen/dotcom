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
    if (this._input) {
      this.init();
    }
  }

  init() {
    this._locationResultsHeader.innerHTML = "";
    this._locationResultsBody.innerHTML = "";
    this._input.value = "";
    this._controller = new Algolia(AlgoliaStopSearch.INDICES, AlgoliaStopSearch.PARAMS);
    this._autocomplete = new AlgoliaAutocompleteWithGeo(AlgoliaStopSearch.SELECTORS,
                                                        Object.keys(AlgoliaStopSearch.INDICES),
                                                        this);
    this._controller.addWidget(this._autocomplete);
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
  locationResultsBody: "stop-search__location-results--body",
  locationResultsHeader: "stop-search__location-results--header",
  locationLoadingIndicator: "stop-search__loading-indicator"
}

AlgoliaStopSearch.PARAMS = {
  stops: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[]]
  }
}
