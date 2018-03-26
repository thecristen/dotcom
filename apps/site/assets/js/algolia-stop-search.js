import { Algolia } from "./algolia-search";
import { AlgoliaAutocomplete } from "./algolia-autocomplete"

export function init() {
  document.addEventListener("turbolinks:load", () => { new AlgoliaStopSearch() });
}

export class AlgoliaStopSearch {
  constructor() {
    this._input = document.getElementById(AlgoliaStopSearch.SELECTORS.input);
    this._controller = null;
    this._autocomplete = null;
    if (this._input) {
      this.init();
    }
  }

  init() {
    this._input.value = "";
    this._controller = new Algolia(AlgoliaStopSearch.INDICES, AlgoliaStopSearch.PARAMS);
    this._autocomplete = new AlgoliaAutocomplete(AlgoliaStopSearch.SELECTORS.input,
                                                 Object.keys(AlgoliaStopSearch.INDICES));
    this._controller.addWidget(this._autocomplete);
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
}

AlgoliaStopSearch.PARAMS = {
  stops: {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [[]]
  }
}
