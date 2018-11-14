import { doWhenGoogleMapsIsReady} from "./google-maps-loaded";
import { AlgoliaEmbeddedSearch } from "./algolia-embedded-search";
import { animatePlaceholder } from "./animated-placeholder";
import { placeholders } from "./search-placeholders";
import * as QueryStringHelpers from "./query-string-helpers";

const INDICES = {
  routes: {
    indexName: "routes",
    query: ""
  },
  stops: {
    indexName: "stops",
    query: ""
  },
  pages: {
    indexName: "drupal",
    query: ""
  },
}

// exported for testing
export const SELECTORS = {
  input: "search-homepage__input",
  container: "search-homepage__container",
  goBtn: "search-homepage__input-go-btn",
  locationLoadingIndicator: "search-homepage__loading-indicator",
  resetButton: "search-homepage__reset",
  announcer: "search-homepage__announcer"
}

const PARAMS = {
  stops: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[]]
  },
  routes: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[]]
  },
  pages: {
    hitsPerPage: 2,
    facets: ["*"],
    facetFilters: [[
      "_content_type:page",
      "_content_type:search_result",
      "_content_type:landing_page",
      "_content_type:person",
      "_content_type:project",
      "_content_type:project_update"
    ]]
  },
}

const LOCATION_PARAMS = {
  position: 3,
  hitLimit: 2
}

// exported for testing
export const doInit = () => {
  const search = new AlgoliaEmbeddedSearch(
    {
      pageId: "search-homepage",
      indices: INDICES,
      params: PARAMS,
      selectors: SELECTORS,
      locationParams: LOCATION_PARAMS,
    }
  );
  search.buildSearchParams = () => {
    return QueryStringHelpers.parseParams({
      query: search.input.value
    });
  };

  return search;
};

export function init() {
  document.addEventListener("turbolinks:load", () => {
    doWhenGoogleMapsIsReady(doInit);

    animatePlaceholder(SELECTORS.input, placeholders);
  });
}
