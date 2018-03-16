import algoliasearch from "algoliasearch"

export class Algolia {
  constructor(indices, defaultParams) {
    this._indices = indices;
    this._searchIndices = indices.slice(0);
    this._defaultParams = defaultParams;
    this.resetSearch();
    this._currentQuery = "";
    this._lastQuery = "";
    this._doBlankSearch = true;
    this._widgets = [];
    this._config = window.algoliaConfig;
    this._client = null;

    if (this._config &&
        this._config.app_id &&
        this._config.search &&
        this._config.places &&
        this._config.places.app_id &&
        this._config.places.search) {
      this._client = algoliasearch(this._config.app_id, this._config.search);
    } else {
      console.error("missing algolia keys", this.config);
    }
  }

  resetSearch() {
    this._params = {};
    this._searchIndices.forEach(index => this._params[index] = JSON.parse(JSON.stringify(this._defaultParams)));
  }

  doBlankSearch(blank) {
    this._doBlankSearch = blank;
  }

  search(query) {
    let searchIndices = this._indices;
    this._doBlankSearch = this._indices.length == 0;
    if (this._doBlankSearch) {
      searchIndices = this._searchIndices;
    }

    if (typeof query == "string") {
      this._currentQuery = query;
    } else {
      this._currentQuery = this._lastQuery;
    }
    const allQueries = this._buildAllQueries(searchIndices);

    this._lastQuery = this._currentQuery;
    this._client.search(allQueries, this.onResults.bind(this));
  }

  _buildAllQueries() {
    const searchIndices = this._indices.length > 0 ? this._indices : this._searchIndices;
    const queries = searchIndices.reduce(this._buildQuery({isFacetQuery: false}), []);
    const facetQueries = this._searchIndices.reduce(this._buildQuery({isFacetQuery: true}), []);
    return queries.concat(facetQueries);
  }

  _buildQuery(isFacetQuery) {
    return (acc, index) => {
      acc.push({
        indexName: index,
        query: this._currentQuery,
        params: this._buildQueryParams(index, isFacetQuery)
      });
      return acc;
    }
  }

  _buildQueryParams(index, {isFacetQuery: isFacetQuery}) {
    if (isFacetQuery === true) {
      return {
        hitsPerPage: 0,
        facets: ["*"]
      }
    }
    return this._params[index];
  }

  updateAllParams(key, value) {
    Object.keys(this._params).forEach(index => this._params[index][key] = value);
  }

  updateIndices(indices) {
    this._indices = indices;
  }

  removeIndex(index) {
    const i = this._indices.indexOf(index);
    if (i != -1) {
      this._indices.splice(i, 1);
    }
  }

  addIndex(index) {
    if (this._indices.indexOf(index) == -1) {
      this._indices.push(index);
    }
  }

  updateFacetFilters(index, filters) {
    this._params[index]["facetFilters"][0] = filters;
  }

  addFacetFilter(index, filter) {
    if (this._params[index]["facetFilters"][0].indexOf(filter) == -1) {
      this._params[index]["facetFilters"][0].push(filter);
    }
  }

  removeFacetFilter(index, filter) {
    const i = this._params[index]["facetFilters"][0].indexOf(filter);
    if (i != -1) {
      this._params[index]["facetFilters"][0].splice(i, 1);
    }
  }

  get_indices() {
    return this._indices;
  }

  updateParams(index, params) {
    this._params[index] = params;
  }

  updateParamsByKey(index, key, value) {
    this._params[index][key] = value;
  }

  getParams(index) {
    return this._params[index];
  }

  addWidget(widget) {
    widget.init();
    this._widgets.push(widget);
  }

  onResults(err, response) {
    let searchResultsLength = this._indices.length;
    if (this._doBlankSearch) {
      searchResultsLength = this._searchIndices.length;
    }
    const searchResults = response.results.slice(0, searchResultsLength);
    const facetResults = response.results.slice(searchResultsLength, searchResultsLength + this._searchIndices.length);
    const results = {}
    searchResults.forEach(function(result) {
      results[result.index] = result;
    });
    facetResults.forEach(function(result) {
      results[`facets-${result.index}`] = result;
    });
    this._widgets.forEach(function(widget) {
      widget.render(results);
    });
  }
}
