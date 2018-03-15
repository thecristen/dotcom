import {FacetBar} from './facet-bar';
import {FacetItem} from './facet-bar';

export class AlgoliaFacets {
  constructor(indices, selectors, search) {
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
        indexName: "routes",
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
            id: "commuter-rail",
            name: "Commuter Rail",
            facets: ["2"],
            icon: this._getFeatureIcon("commuter_rail")
          },
          {
            id: "bus",
            name: "Bus",
            facets: ["3"],
            icon: this._getFeatureIcon("bus")
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
        indexName: "stops",
        facetName: "routes.icon",
        items: [
        {
          id: "stops",
          name: "Stations and Stops",
          items: [
          {
            id: "stop-bus",
            name: "Bus",
            facets: ["bus"],
            icon: this._getFeatureIcon("bus")
          },
          {
            id: "stop-cr",
            name: "Commuter Rail",
            facets: ["commuter_rail"],
            icon: this._getFeatureIcon("commuter_rail")
          },
          {
            id: "stop-green",
            name: "Green Line",
            facets: ["green_line"],
            icon: this._getFeatureIcon("green_line")
          },
          {
            id: "stop-red",
            name: "Red Line",
            facets: ["red_line"],
            icon: this._getFeatureIcon("red_line")
          },
          {
            id: "stop-orange",
            name: "Orange Line",
            facets: ["orange_line"],
            icon: this._getFeatureIcon("orange_line")
          },
          {
            id: "stop-blue",
            name: "Blue Line",
            facets: ["blue_line"],
            icon: this._getFeatureIcon("blue_line")
          },
          {
            id: "stop-mattapan",
            name: "Mattapan Trolley",
            facets: ["mattapan_trolley"],
            icon: this._getFeatureIcon("mattapan_trolley")
          },
          {
            id: "stop-ferry",
            name: "Ferry",
            facets: ["ferry"],
            icon: this._getFeatureIcon("ferry")
          },
          ]
        }
        ]
      },
      drupal: {
        indexName: "drupal",
        facetName: "_content_type",
        items: [
        {
          id: "pages-parent",
          name: "Pages and Documents",
          items: [
          {
            id: "page",
            name: "Pages",
            facets: ["page"],
            icon: this._faIcon("fa-file-o"),
          },
          {
            id: "people",
            name: "People",
            facets: ["person"],
            icon: this._faIcon("fa-user")
          },
          {
            id: "landing",
            name: "Landing Pages",
            facets: ["landing_page"],
            icon: this._faIcon("fa-file-o")
          },
          {
            id: "project",
            name: "Projects",
            facets: ["project"],
            icon: this._faIcon("fa-file-o")
          },
          {
            id: "project-update",
            name: "Project Updates",
            facets: ["project_update"],
            icon: this._faIcon("fa-file-o")
          },
          ]
        },
        {
          id: "event",
          name: "Events",
          icon: this._faIcon("fa-calendar"),
          facets: ["event"],
        },
        {
          id: "news",
          name: "News",
          icon: this._faIcon("fa-newspaper-o"),
          facets: ["news_entry"],
        },
        ]
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
