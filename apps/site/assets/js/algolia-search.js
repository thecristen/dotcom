import algoliasearch from "algoliasearch";

export class Algolia {
  constructor(queries, defaultParams) {
    this._queries = queries;
    this._activeQueryIds = Object.keys(queries);
    this._defaultParams = defaultParams;
    this._viewMoreInc = 20;
    this._lastQuery = "";
    this._doBlankSearch = true;
    this._widgets = [];
    this.reset();
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

  get client() {
    return this._client;
  }

  get widgets() {
    return this._widgets;
  }

  reset() {
    Object.keys(this._queries).forEach(this.resetDefaultParams());
    this._lastQuery = "";
    this.resetWidgets();
  }

  resetDefaultParams() {
    return (queryId) => {
      if (this._defaultParams[queryId]) {
        this._queries[queryId].params = JSON.parse(JSON.stringify(this._defaultParams[queryId]));
      } else {
        console.error("default params not set for queryId", queryId, this._defaultParams);
      }
    }
  }

  addPage(group) {
    this._queries[group].params.hitsPerPage += this._viewMoreInc;
    this.search({});
  }

  search(opts = {}) {
    if (!(typeof opts.query == "string")) { opts.query = this._lastQuery; }
    if (opts.query.length > 0) {
      const allQueries = this._buildAllQueries(opts);
      this._lastQuery = opts.query;
      return this._doSearch(allQueries);
    } else {
      this.updateWidgets({});

      // This code handles the case where the user backspaces to an empty search string
      if (this._lastQuery.length > 0) {
        this.reset();
      }
      return Promise.resolve({});
    }
  }

  _doSearch(allQueries) {
    return this._client.search(allQueries)
               .then(this._processAlgoliaResults())
               .then(results => {
                 this.updateWidgets(results)
                 return results;
               })
               .catch(err => console.log(err));
  }

  _buildAllQueries(opts) {
    const requestedQueryIds = this._activeQueryIds.length > 0 ? this._activeQueryIds : Object.keys(this._queries);
    const queries = [];
    requestedQueryIds.forEach(queryId => {
      queries.push(this._buildQuery(queryId, opts))
    });
    Object.keys(this._queries).forEach(queryId => {
      queries.push(this._buildFacetQuery(queryId, opts))
    });
    return queries;
  }

  _buildFacetQuery(queryId, opts) {
    return {
      indexName: this._queries[queryId].indexName,
      query: opts.query,
      params: {
        hitsPerPage: 0,
        facets: ["*"]
      }
    }
  }

  _buildQuery(queryId, { query }) {
    const currentQuery = this._queries[queryId];
    currentQuery.query = query;
    return currentQuery;
  }

  updateAllParams(key, value) {
    Object.keys(this._queries).forEach(key => this._queries[key].params[key] = value);
  }

  updateActiveQueries(queryIds) {
    this._activeQueryIds = queryIds;
  }

  removeActiveQuery(queryId) {
    const i = this._activeQueryIds.indexOf(queryId);
    if (i != -1) {
      this._activeQueryIds.splice(i, 1);
    }
  }

  addActiveQuery(queryId) {
    if (this._activeQueryIds.indexOf(queryId) == -1) {
      this._activeQueryIds.push(queryId);
    }
  }

  updateFacetFilters(queryId, filters) {
    this._queries[queryId].params["facetFilters"][0] = filters;
  }

  addFacetFilter(queryId, filter) {
    if (this._queries[queryId].params["facetFilters"][0].indexOf(filter) == -1) {
      this._queries[queryId].params["facetFilters"][0].push(filter);
    }
  }

  removeFacetFilter(queryId, filter) {
    const i = this._queries[queryId].params["facetFilters"][0].indexOf(filter);
    if (i != -1) {
      this._queries[queryId].params["facetFilters"][0].splice(i, 1);
    }
  }

  updateParams(queryId, params) {
    this._queries[queryId].params = params;
  }

  updateParamsByKey(queryId, key, value) {
    this._queries[queryId].params[key] = value;
  }

  getParams(queryId) {
    return this._queries[queryId].params;
  }

  addWidget(widget) {
    widget.init(this);
    this._widgets.push(widget);
  }

  updateWidgets(results) {
    this._widgets.forEach(function(widget) {
      if (typeof widget.render === "function") {
        widget.render(results);
      }
    });
  }

  resetWidgets() {
    this._widgets.forEach(function(widget) {
      if (typeof widget.reset === "function") {
        widget.reset();
      }
    });
  }

  _processAlgoliaResults() {
    return (response) => {
      let searchedQueries = this._activeQueryIds.slice(0);
      if (this._activeQueryIds.length == 0) {
        searchedQueries = Object.keys(this._queries);
      }
      const facetLength = Object.keys(this._queries).length;
      const searchResults = response.results.slice(0, searchedQueries.length);
      const facetResults = response.results.slice(searchedQueries.length, searchedQueries.length + facetLength);
      const results = {}
      searchResults.forEach((result, i) => {
        results[searchedQueries[i]] = result;
      });
      facetResults.forEach((result, i) => {
        results[`facets-${Object.keys(this._queries)[i]}`] = result;
      });
      return Promise.resolve(results);
    }
  }
}
