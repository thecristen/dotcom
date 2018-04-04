import * as AlgoliaResult from "./algolia-result";

export class AlgoliaAutocomplete {
  constructor(selectors, indices) {
    this._selectors = Object.assign(selectors, {
      resultsContainer: selectors.input + "-autocomplete-results",
      goBtn: selectors.input + "-go-btn"
    });
    this._input = document.getElementById(this._selectors.input);
    this._resultsContainer = document.getElementById(this._selectors.resultsContainer);
    this._goBtn = document.getElementById(this._selectors.goBtn);
    this._indices = indices;
    this._datasets = [];
    this._results = {};
    this._highlightedHit = null;
    this._autocomplete = null;
    this.bind();
  }

  bind() {
    this.onHitSelected = this.onHitSelected.bind(this);
    this.onClickGoBtn = this.onClickGoBtn.bind(this);
    this.onCursorChanged = this.onCursorChanged.bind(this);
    this.onCursorRemoved = this.onCursorRemoved.bind(this);
  }

  init(client) {
    this._client = client;

    if (!this._input) {
      console.error(`could not find autocomplete input: ${this._selectors.input}`);
      return false
    }

    this._addGoBtn();
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

    this._goBtn.removeEventListener("click", this.onClickGoBtn);
    this._goBtn.addEventListener("click", this.onClickGoBtn);
  }

  _addResultsContainer() {
    if (!this._resultsContainer) {
      this._resultsContainer = document.createElement("div");
      this._resultsContainer.id = this._selectors.resultsContainer;
      this._input.parentNode.appendChild(this._resultsContainer);
    }
  }

  _addGoBtn() {
    if (!this._goBtn) {
      this._goBtn = document.createElement("div");
      this._goBtn.id = this._selectors.goBtn;
      this._goBtn.classList.add("c-search-bar__go-btn");
      this._goBtn.innerHTML = `GO`;
      this._input.parentNode.appendChild(this._goBtn);
    }
    return this._goBtn;
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

  onClickGoBtn(ev) {
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

AlgoliaAutocomplete.DISPLAY_KEYS = {
  locations: "hit.place_id",
}
