import * as AlgoliaResult from "./algolia-result";

export class AlgoliaAutocomplete {
  constructor(selectors, indices) {
    this._selectors = Object.assign(selectors, {
      container: selectors.input + "-autocomplete-container"
    });
    this._input = document.getElementById(this._selectors.input);
    this._container = document.getElementById(this._selectors.container);
    this._indices = indices;
    this._datasets = [];
    this._results = {};
    this._autocomplete = null;
    this.onHitSelected = this.onHitSelected.bind(this);
  }

  init(client) {
    this._client = client;

    if (!this._input) {
      console.error(`could not find autocomplete container: ${this._selectors.input}`);
      return false
    }

    if (!this._container) {
      this._container = document.createElement("div");
      this._container.id = this._selectors.container;
      this._input.parentNode.appendChild(this._container);
    }
    this._container.innerHTML = "";

    this._datasets = this._indices.reduce((acc, index) => { return this._buildDataset(index, acc) }, []);

    this._autocomplete = window.autocomplete(this._input, {
      appendTo: "#" + this._selectors.container,
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

    document.removeEventListener("autocomplete:selected", this.onHitSelected);
    document.addEventListener("autocomplete:selected", this.onHitSelected);
  }

  onHitSelected({_args: [{url, _id}, _index]}) {
    if (this._input) {
      this._input.value = "";
    }
    window.Turbolinks.visit(url);
  }

  _buildDataset(indexName, acc) {
    acc.push({
      source: this._datasetSource(indexName),
      displayKey: AlgoliaAutocomplete.DISPLAY_KEYS[indexName],
      name: indexName,
      hitsPerPage: this._hitsPerPage(indexName),
      templates: {
        header: this._renderHeaderTemplate(indexName),
        suggestion: this.renderResult(indexName)
      }
    });
    return acc;
  }

  _hitsPerPage(_indexName) {
    return 5;
  }

  _renderHeaderTemplate(indexName) {
    const titles = {
      locations: "Location Results",
      stops: "MBTA Station Results"
    }
    return titles[indexName] ? `<p class="c-search-bar__results-header">${titles[indexName]}</p>` : ""
  }

  _datasetSource(index) {
    return (query, callback) => {
      this._client.resetSearch();
      return this._client.search(query)
             .then(results => this._onResults(callback, index, results))
             .catch(err => console.error(err))
    }
  }

  _emptySearchSource(_index) {
    return (query, callback) => callback([{data: ""}])
  }

  _onResults(callback, index, results) {
    if (results[index] && results[index].hits) {
      callback(results[index].hits);
    } else {
      console.error(`expected results["${index}"].hits, got:`, results);
    }
  }

  renderResult(index) {
    return (hit) => AlgoliaResult.renderResult(hit, index)
  }

  render(results) {
    this._results = results;
  }
}

AlgoliaAutocomplete.DISPLAY_KEYS = {
  locations: "hit.place_id",
}
