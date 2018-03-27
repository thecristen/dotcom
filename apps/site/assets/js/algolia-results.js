import hogan from 'hogan.js';
import * as AlgoliaResult from "./algolia-result";
import * as GoogleMapsHelpers from "./google-maps-helpers";

const TEMPLATES = {
  contentResults: hogan.compile(`
    <div class="c-search-results__section">
      {{#hasHits}}
        <div class="c-search-result__header">
          {{title}}
          {{#isLocation}}
          <div id="search-result__use-my-location" class="c-search-result__header--location">
          <i aria-hidden="true" class="fa fa-location-arrow "></i>
          Use my location
          <i aria-hidden="true" id="search-result__loading-indicator" class="fa fa-cog fa-spin c-search-result__loading-indicator"></i>
          </div>
          {{/isLocation}}
        </div>
        {{{hits}}}
      {{/hasHits}}
    </div>
 `),
};

export class AlgoliaResults {
  constructor(id) {
    this._id = id
    this._container = document.getElementById(this._id);
    if (!this._container) {
      console.error(`could not find results container with id: ${this._id}`);
    }
    this._container.innerHTML = "";
  }

  _renderIndex(results, index) {
    if (results[index]) {
      return TEMPLATES.contentResults.render({
        title: AlgoliaResults.indexTitles[index] || "",
        isLocation: index == "locations" || null,
        nbHits: results[index].nbHits,
        hasHits: results[index].nbHits > 0,
        hits: results[index].hits.slice(0)
                                 .map(this.renderResult(index))
                                 .join("")
      });
    }
    return "";
  }

  _addLocationListeners(results) {
    if (results["locations"]) {
      results["locations"].hits.forEach(hit => {
        const elem = document.getElementById(`hit-${hit.place_id}`);
        if (elem) {
          elem.addEventListener("click", this._locationSearch(hit.place_id));
        }
      });
      const useLocation = document.getElementById("search-result__use-my-location")
      if(useLocation){
        useLocation.addEventListener("click", () => {
          this._useMyLocation()
          .then(pos => {
            this._locationSearchByGeo(pos.coords.latitude, pos.coords.longitude);
          })
          .catch(err => {
            console.error(err);
          });
        });
      }
    }
  }

  _showLocation(latitude, longitude, address) {
    Turbolinks.visit(`/transit-near-me?latitude=${latitude}&longitude=${longitude}&location[address]=${address}`);
  }

  _locationSearchByGeo(latitude, longitude) {
    GoogleMapsHelpers.reverseGeocode(parseFloat(latitude), parseFloat(longitude))
      .then(result => {
        document.getElementById("search-result__loading-indicator").style.display = "none";
        this._showLocation(latitude, longitude, result);
      })
    .catch(err => {console.error("Problem with retrieving location using the Google Maps API.");});
  }

  _locationSearch(placeId) {
    return () => {
      GoogleMapsHelpers.lookupPlace(placeId)
        .then(result => {
          this._showLocation(result.geometry.location.lat(),
                             result.geometry.location.lng(),
                             result.formatted_address);
        })
        .catch(err => {console.error(err);});
    }
  }

  _useMyLocation() {
    document.getElementById("search-result__loading-indicator").style.display = "inline-block";
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(
        pos => {
          return resolve(pos);
        },
        err => {
          return reject(err);
        }
      );
    });
  }

  init() {
  }

  render(results)  {
    if (this._container) {
      this._container.innerHTML =
        ["locations", "routes", "stops", "pagesdocuments", "events", "news"]
        .map(index => this._renderIndex(results, index))
        .join("");
      this._addLocationListeners(results);
    }
  }

  renderResult(index) {
    return (hit) => {
      return `
        <div class="c-search-result__hit">
          ${AlgoliaResult.renderResult(hit, index)}
        </div>
      `;
    }
  }
}

AlgoliaResults.indexTitles = {
  locations: "Locations",
  stops: "Stations and Stops",
  routes: "Lines and Routes",
  pagesdocuments: "Pages and Documents",
  events: "Events",
  news: "News"
}
