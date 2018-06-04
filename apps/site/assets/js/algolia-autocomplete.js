import * as AlgoliaResult from "./algolia-result";
import * as QueryStringHelpers from "./query-string-helpers";

export class AlgoliaAutocomplete {
  constructor(selectors, indices, headers, parent) {
    this._parent = parent;
    this._selectors = Object.assign(selectors, {
      resultsContainer: selectors.input + "-autocomplete-results"
    });
    this._input = document.getElementById(this._selectors.input);
    this._resultsContainer = document.getElementById(this._selectors.resultsContainer);
    this._searchContainer = document.getElementById(this._selectors.container);
    this._indices = indices;
    this._headers = Object.assign(AlgoliaAutocomplete.DEFAULT_HEADERS, headers);
    this._datasets = [];
    this._results = {};
    this._highlightedHit = null;
    this._autocomplete = null;
    this.bind();
  }

  bind() {
    this.onClickSuggestion = this.onClickSuggestion.bind(this);
    this.onHitSelected = this.onHitSelected.bind(this);
    this.onCursorChanged = this.onCursorChanged.bind(this);
    this.onCursorRemoved = this.onCursorRemoved.bind(this);
    this.onOpen = this.onOpen.bind(this);
  }

  init(client) {
    this._client = client;

    if (!this._input) {
      console.error(`could not find autocomplete input: ${this._selectors.input}`);
      return false
    }

    this._addResultsContainer();

    this._resultsContainer.innerHTML = "";

    this._datasets = this._indices.reduce((acc, index) => { return this._buildDataset(index, acc) }, []);

    this._autocomplete = window.autocomplete(this._input, {
      appendTo: "#" + this._selectors.resultsContainer,
      debug: false,
      autoselectOnBlur: false,
      openOnFocus: true,
      hint: false,
      minLength: 1,
      cssClasses: {
        root: "c-search-bar__autocomplete",
        prefix: "c-search-bar__"
      }
    }, this._datasets);

    this._addListeners()
  }

  _addListeners() {
    document.removeEventListener("autocomplete:cursorchanged", this.onCursorChanged);
    document.addEventListener("autocomplete:cursorchanged", this.onCursorChanged);

    document.removeEventListener("autocomplete:cursorremoved", this.onCursorRemoved);
    document.addEventListener("autocomplete:cursorremoved", this.onCursorRemoved);

    document.removeEventListener("autocomplete:selected", this.onHitSelected);
    document.addEventListener("autocomplete:selected", this.onHitSelected);

    document.removeEventListener("autocomplete:shown", this.onOpen);
    document.addEventListener("autocomplete:shown", this.onOpen);

    window.removeEventListener("resize", this.onOpen);
    window.addEventListener("resize", this.onOpen);

    // normally we would only use `.js-` prefixed classes for javascript selectors, but
    // we make an exception here because this element and its class is generated entirely
    // by the autocomplete widget.
    window.jQuery(document).off("click", ".c-search-bar__-suggestion", this.onClickSuggestion);
    window.jQuery(document).on("click", ".c-search-bar__-suggestion", this.onClickSuggestion);
  }

  onOpen() {
    const acDialog = document.getElementsByClassName("c-search-bar__-dropdown-menu")[0];
    const homepageSearchBox = document.getElementsByClassName("js-homepage-search-input");

    const borderWidth = parseInt($(`#${this._selectors.container}`).css("border-left-width"));

    acDialog.style.width = `${this._searchContainer.offsetWidth}px`;
    acDialog.style.marginLeft = `${-borderWidth}px`;
    acDialog.style.marginTop = `${2 * borderWidth}px`;
  }

  _addResultsContainer() {
    if (!this._resultsContainer) {
      this._resultsContainer = document.createElement("div");
      this._resultsContainer.id = this._selectors.resultsContainer;
      this._input.parentNode.appendChild(this._resultsContainer);
    }
  }

  onCursorChanged({_args: [hit, index]}) {
    this._highlightedHit = {
      hit: hit,
      index: index
    };
  }

  onCursorRemoved(ev) {
    this._highlightedHit = null;
  }

  clickHighlightedOrFirstResult() {
    if (this._highlightedHit) {
      return this.onHitSelected({_args: [this._highlightedHit.hit, this._highlightedHit.index]});
    }
    return this.clickFirstResult();
  }

  clickFirstResult() {
    const firstIndex = this._indices.find(index => {
      return this._results[index] &&
             this._results[index].hits.length > 0
    });
    if (firstIndex) {
      return this.onHitSelected({
        _args: [this._results[firstIndex].hits[0], firstIndex]
      });
    }
    return false;
  }

  onClickSuggestion(ev) {
    ev.preventDefault();
  }

  onHitSelected({_args: [hit, type]}) {
    const params = this._parent.getParams();
    if (this._input) {
      this._input.value = "";
    }
    window.Turbolinks.visit(AlgoliaResult.getUrl(hit, type) + QueryStringHelpers.parseParams(params));
  }

  _buildDataset(indexName, acc) {
    acc.push({
      source: this._datasetSource(indexName),
      displayKey: AlgoliaAutocomplete.DISPLAY_KEYS[indexName],
      name: indexName,
      hitsPerPage: 5,
      templates: {
        header: this.renderHeaderTemplate(indexName),
        suggestion: this.renderResult(indexName),
        footer: this.renderFooterTemplate(indexName),
      }
    });
    return acc;
  }

  renderHeaderTemplate(indexName) {
    // Default header template simply includes the index name
    // To render a different header template, override this method.
    return `<p class="c-search-bar__results-header">${this._headers[indexName]}</p>`;
  }

  renderFooterTemplate(_indexName) {
    // Does not render a footer template by default.
    // To render a footer template, override this method.
    return null;
  }

  _datasetSource(index) {
    return (query, callback) => {
      this._client.reset();
      return this._client.search({query: query})
             .then(results => this._onResults(callback, index, results))
             .catch(err => console.error(err))
    }
  }

  _emptySearchSource(_index) {
    return (query, callback) => callback([{data: ""}])
  }

  _onResults(callback, index, results) {
    if (results[index] && results[index].hits) {
      this._results[index] = results[index]
      callback(results[index].hits);
    } else {
      console.error(`expected results["${index}"].hits, got:`, results);
    }
  }

  renderResult(index) {
    return (hit) => AlgoliaResult.renderResult(hit, index)
  }
}

AlgoliaAutocomplete.DEFAULT_HEADERS = {
  stops: "Stations and Stops",
  routes: "Lines and Routes",
  pagesdocuments: "Pages and Documents",
  events: "Events",
  news: "News",
  locations: "Locations"
}

AlgoliaAutocomplete.DISPLAY_KEYS = {
  locations: "hit.place_id",
}
