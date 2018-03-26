import * as AlgoliaResult from "./algolia-result";

export class AlgoliaAutocomplete {
  constructor(selector, indices) {
    this._selectors = {
      input: selector,
      container: selector + "-autocomplete-container"
    };
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
      console.error(`could not find autocomplete container: ${this._selector}`);
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

    document.addEventListener("autocomplete:selected", this.onHitSelected);
  }

  onHitSelected({_args: [{url}, _index]}) {
    document.removeEventListener("autocomplete:selected", this.onHitSelected);
    if (this._input) {
      this._input.value = "";
    }
    window.Turbolinks.visit(url);
  }

  _buildDataset(indexName, acc) {
    switch (indexName) {
      case "stops":
        acc.push({
          source: this._datasetSource("stops"),
          displayKey: "data.stop.name",
          name: "stops",
          hitsPerPage: 5,
          templates: {
            header: '<p class="c-search-bar__results-header">MBTA station results</p>',
            suggestion: this.renderResult("stops")
          }
        });
        break;
      default:
        console.error(`AlgoliaAutocomplete.prototype._addDataset not implemented for ${indexName}`);
    }
    return acc;
  }

  _datasetSource(index) {
    return (query, callback) => {
      return this._client.search(query)
             .then(results => this._onResults(callback, index, results))
             .catch(err => console.error(err))
    }
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

AlgoliaAutocomplete.addStopsDataset = function(acc, client) {
  acc.push();
  return acc;
}
