export const PAGE_IDS = [
  "search-stop",
  "search-route",
  "search-route--subway",
  "search-route--commuter_rail",
  "search-route--bus",
  "search-route--ferry"
];

export const FACET_MAP = {
  "search-stop": "stations,stops",
  "search-route": "subway,commuter-rail,bus,ferry",
  "search-route--subway": "subway",
  "search-route--commuter_rail": "commuter-rail",
  "search-route--bus": "bus",
  "search-route--ferry": "ferry"
};

const FACET_FILTER_MAP = {
  "search-stop": [],
  "search-route": [0, 1, 2, 3, 4].map(type => `route.type:${type}`),
  "search-route--subway": ["route.type:0", "route.type:1"],
  "search-route--commuter_rail": ["route.type:2"],
  "search-route--bus": ["route.type:3"],
  "search-route--ferry": ["route.type:4"]
};

export const buildOptions = pageId => {

  const selectors = {
    input: `${pageId}__input`,
    container: `${pageId}__container`,
    goBtn: `${pageId}__input-go-btn`,
    locationLoadingIndicator: `${pageId}__loading-indicator`,
    resetButton: `${pageId}__reset`
  };

  const params = {};

  const indices = {};

  const index = pageId === "search-stop" ? "stops" : "routes";

  params[index] = {
    hitsPerPage: 5,
    facets: ["*"],
    facetFilters: [FACET_FILTER_MAP[pageId]]
  };

  indices[index] = {
    indexName: index,
    query: ""
  };

  return {
    selectors,
    params,
    indices
  }
}
