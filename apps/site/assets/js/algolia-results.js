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
        <div class="c-search-results__hits">
          {{#hits}}
              {{{.}}}
          {{/hits}}
          {{#showMore}}
            <div id="show-more--{{group}}" class="c-search-results__show-more" data-group="{{group}}">
              Show more
            </div>
          {{/showMore}}
        </div>
      {{/hasHits}}
    </div>
 `),
};

export class AlgoliaResults {
  constructor(id, parent) {
    this._parent = parent;
    this._groups = ["locations", "routes", "stops", "pagesdocuments", "events", "news"];
    this._container = document.getElementById(id);
    if (!this._container) {
      console.error(`could not find results container with id: ${id}`);
    }
    this._container.innerHTML = "";
    this._bind();
  }

  _bind() {
    this.onClickShowMore = this.onClickShowMore.bind(this);
    this.onClickResult = this.onClickResult.bind(this);
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

  _addShowMoreListener(groupName) {
    const el = document.getElementById("show-more--" + groupName)
    if (el) {
      el.removeEventListener("click", this.onClickShowMore);
      el.addEventListener("click", this.onClickShowMore);
    }
  }

  onClickResult(ev) {
    if (ev.currentTarget.href) {
      ev.preventDefault();
      window.Turbolinks.visit(ev.currentTarget.href + AlgoliaResult.parseParams(this._parent.getParams()));
    }
  }

  onClickShowMore(ev) {
    this._parent.onClickShowMore(ev.target.getAttribute("data-group"));
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
    window.jQuery(document).off("click", ".c-search-result__link", this.onClickResult)
    window.jQuery(document).on("click", ".c-search-result__link", this.onClickResult)
  }

  reset() {
    this.render({});
  }

  render(results)  {
    if (this._container) {
      this._container.innerHTML =
        this._groups
            .map(group => this._renderGroup(results, group))
            .join("");
      this._groups.forEach(group => this._addShowMoreListener(group));
      this._addLocationListeners(results);
    }
  }

  _renderGroup(results, group) {
    if (!results[group]) {
      return "";
    }

    return TEMPLATES.contentResults.render({
      title: AlgoliaResults.indexTitles[group] || "",
      isLocation: group == "locations" || null,
      nbHits: results[group].nbHits,
      hasHits: results[group].nbHits > 0,
      showMore: results[group].hits.length < results[group].nbHits,
      group: group,
      hits: results[group].hits
                          .map(this.renderResult(group))
    });
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
