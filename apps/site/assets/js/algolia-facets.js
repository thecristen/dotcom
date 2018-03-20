import {FacetBar} from './facet-bar';
import {FacetItem} from './facet-bar';

export class AlgoliaFacets {
  constructor(selectors, search) {
    document.getElementById(selectors.closeModalButton).addEventListener("click", function() {
      document.getElementById(selectors.facetsContainer).classList.remove("c-searchv2__facets-container--open");
      document.getElementById(selectors.closeModalButton).classList.remove("c-searchv2__close-modal-button--open");
      document.body.classList.remove("c-searchv2__open-modal");
    });
    document.getElementById(selectors.showFacetsButton).addEventListener("click", function() {
      document.getElementById(selectors.facetsContainer).classList.add("c-searchv2__facets-container--open");
      document.getElementById(selectors.closeModalButton).classList.add("c-searchv2__close-modal-button--open");
      document.body.classList.add("c-searchv2__open-modal");
    });

    const facets = {
      routes: {
        queryId: "routes",
        facetName: "route.type",
        items: [
        {
          id: "lines-routes",
          name: "Lines and Routes",
          items: [
          {
            id: "subway",
            name: "Subway",
            facets: ["0", "1"],
            icon: this._getFeatureIcon("red_line")
          },
          {
            id: "bus",
            name: "Bus",
            facets: ["3"],
            icon: this._getFeatureIcon("bus")
          },
          {
            id: "commuter-rail",
            name: "Commuter Rail",
            facets: ["2"],
            icon: this._getFeatureIcon("commuter_rail")
          },
          {
            id: "ferry",
            name: "Ferry",
            facets: ["4"],
            icon: this._getFeatureIcon("ferry")
          },
          ]
        }
        ]
      },
      stops: {
        queryId: "stops",
        facetName: "stop.station?",
        items: [
        {
          id: "stops",
          name: "Stations and Stops",
          items: [
          {
            id: "facet-station",
            name: "Stations",
            facets: ["true"],
            icon: this._getFeatureIcon("bus")
          },
          {
            id: "facet-stop",
            name: "Stops",
            facets: ["false"],
            icon: this._getFeatureIcon("commuter_rail")
          },
          ]
        }
        ]
      },
      pagesdocuments: {
        queryId: "pagesdocuments",
        facetName: "_content_type",
        items: [
        {
          id: "pages-parent",
          name: "Pages and Documents",
          items: [
          {
            id: "page",
            name: "Pages",
            facets: ["page", "search_result", "landing_page", "person", "project", "project_update"],
            icon: this._faIcon("fa-file-o"),
          },
          {
            id: "document",
            name: "Documents",
            prefix: "search_api_datasource",
            facets: ["entity:file"],
            icon: this._faIcon("fa-file-o")
          },
          ]
        }]
      },
      events: {
        queryId: "events",
        facetName: "_content_type",
        items: [{
          id: "event",
          name: "Events",
          icon: this._faIcon("fa-calendar"),
          facets: ["event"],
        }]
      },
      news: {
        queryId: "news",
        facetName: "_content_type",
        items: [{
          id: "news",
          name: "News",
          icon: this._faIcon("fa-newspaper-o"),
          facets: ["news_entry"],
        }]
      }
    }
    this._facetBar = new FacetBar("search-facets-container", search, facets);
  }

  _getFeatureIcon(feature) {
    const icon = document.getElementById(`icon-feature-${feature}`);
    if (icon) {
      return icon.innerHTML;
    }
    return "";
  }

  _faIcon(icon) {
    return `<span aria-hidden="true" class="c-search-result__content-icon fa ${icon}"></span>`;
  }

  init() {
  }

  render(results) {
    const facetResults = {};
    Object.keys(results).forEach(key => {
      if (key.startsWith("facets-")) {
        const facets = results[key].facets;
        Object.keys(facets).forEach(prefix => {
          const values = facets[prefix]
          Object.keys(values).forEach(facet => {
            facetResults[`${prefix}:${facet}`] = values[facet];
          });
        });
      }
    });
    this._facetBar.updateCounts(facetResults);
  }
}
