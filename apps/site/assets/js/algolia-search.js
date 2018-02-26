import algoliasearch from 'algoliasearch';
import autocomplete from 'autocomplete.js';
import hogan from 'hogan.js';
import placesAutocompleteDataset from 'places.js/autocompleteDataset.js';

export default function() {
  const metersPerMile = 1609.34;
  const SELECTORS = {
    searchBar: "search-bar",
    locationResults: {
      template: "location-result-template",
      header: "location-result-header",
      body: "location-result-body"
    }
  }

  const TEMPLATES = {
    stopSuggestion: hogan.compile(`
      <a class="stop-btn m-stop-results" href="/stops/{{stop.id}}">
        <span class="c-search-bar__stop-name js-stop__name">{{stop.name}}</span>
        <span>
          {{{renderedFeatures}}}
          {{#zone}}
            <span class="commuter-rail-zone">Zone {{zone}}</span>
          {{/zone}}
        </span>
      </a>
      `),
    locationResultHeader: hogan.compile(`
      <h5>
        Stations near "{{name}}..."
      </h5>
      `),
    locationResult: hogan.compile(`
      <div class="c-location-cards c-location-cards--background-white large-set c-search-bar__cards">
          {{#hits}}
          <a class="c-location-card" href="/stops/{{stop.id}}">
            <div class="c-location-card__name">
              {{stop.name}}
            </div>
            <div class="c-location-card__distance">
              {{_rankingInfo.geoDistance}} mi
            </div>

            <div class="c-location-card__description">
            {{#routes}}
              <div class="c-location-card__transit-route-icon">
                {{{icon}}}
              </div>
              <div class="c-location-card__transit-route-name">
                {{display_name}}
              </div>
            {{/routes}}
            </div>
          </a>
        {{/hits}}
        </div>
      `),
  }

  if (document.getElementById(SELECTORS.searchBar)) {
    document.addEventListener("turbolinks:load", doSetupSearch, {passive: true});
  }
  function doSetupSearch() {
    const ALGOLIA = window.algoliaConfig;
    const client = algoliasearch(ALGOLIA.algolia_app_id, ALGOLIA.algolia_api_key);
    const stopsIndex = client.initIndex("stops");

    function renderSuggestion(suggestion) {
      let featureIcons = suggestion.features.map(getFeatureIcon).join("");
      suggestion.renderedFeatures = featureIcons;
      return TEMPLATES.stopSuggestion.render(suggestion);
    }

    function getFeatureIcon(feature) {
      return document.getElementById(`icon-feature-${feature}`).innerHTML;
    }

    function stopsLengthWrapper(query, callback) {
      if (document.querySelector("#search-bar").value.length >= 1) {
        return autocomplete.sources.hits(stopsIndex, {hitsPerPage: 5})(query, callback);
      }
      return function(query, callback) {callback()};
    }

    let stopsDataset = {
      source: stopsLengthWrapper,
      displayKey: "data.stop.name",
      name: "stops",
      hitsPerPage: 5,
      templates: {
        header: '<p class="c-search-bar__results-header">MBTA station results</p>',
        suggestion: renderSuggestion
      }
    };

    function dummySearch(query, callback) {
      callback([{data: ""}]);
      return
    }

    let dummyDataset = {
      source: dummySearch,
      name: "currentLocation",
      templates: {
        suggestion: function(res){
          return '<span id="my-location" class="c-search-bar__my-location"><i aria-hidden="true" class="fa fa-location-arrow "></i> Use my location</span>'
        }
      }
    };


    const placesDataset = placesAutocompleteDataset({
      algoliasearch: algoliasearch,
      style: false,
      templates: {
        header: '<p class="c-search-bar__results-header">Location results</p>',
      },
      insideBoundingBox: "41.3193,-71.9380,42.8266,-69.6189",
      hitsPerPage: 5
    });

    const placesIndex = placesDataset.source;
    function placesLengthWrapper(query, callback) {
      if (document.getElementById(SELECTORS.searchBar).value.length >= 1) {
        return placesIndex(query, callback);
      }
      return function(query, callback) {callback()};
    }
    placesDataset.source = placesLengthWrapper;

    const autocompleteInstance = autocomplete(document.getElementById(SELECTORS.searchBar), {
      debug: false,
      autoselectOnBlur: false,
      openOnFocus: true,
      hint: false,
      minLength: 0,
      cssClasses: {
        root: "c-search-bar__autocomplete",
        prefix: "c-search-bar__"
      },
    }, [
    dummyDataset,
    stopsDataset,
    placesDataset
    ]);

    function metersToMiles(meters) {
      return (meters / metersPerMile).toFixed(1);
    }

    function truncateSearch(search) {
      let split = search.split(", ");
      return [split[0], split[1]].join(", ");
    }

    function doGeoSearch(coordinates) {
      document.getElementById(SELECTORS.locationResults.header).innerHTML = "";
      stopsIndex.search({
        getRankingInfo: true,
        aroundLatLng: `${coordinates.lat}, ${coordinates.lng}`,
        // ~ 20 miles in meters
        aroundRadius: 32186,
        hitsPerPage: 12,
      }).then(res => {
        res.hits = res.hits.map(function(hit) {
          hit._rankingInfo.geoDistance = metersToMiles(hit._rankingInfo.geoDistance);
          hit.routes = hit.routes.map(function(route) {
            route.icon = getFeatureIcon(route.icon);
            return route;
          });
          return hit;
        });
        let div = document.createElement("div");
        div.innerHTML = TEMPLATES.locationResult.render(res);
        document.getElementById(SELECTORS.locationResults.body).appendChild(div);
        document.getElementById(SELECTORS.locationResults.header).innerHTML = TEMPLATES.locationResultHeader.render({
          name: truncateSearch(document.getElementById(SELECTORS.searchBar).value)
        });
      });
    }

    let places = algoliasearch.initPlaces(ALGOLIA.algolia_places_app_id, ALGOLIA.algolia_places_api_key)
    function locationHandler(pos) {
      places.search({
        getRankingInfo: true,
        type: "address",
        aroundLatLng: `${pos.coords.latitude}, ${pos.coords.longitude}`,
        aroundRadius: 100,
        hitsPerPage: 10,
      }).then(res => {
        let firstHit = res.hits[0]._highlightResult;
        let address = `${firstHit.locale_names.default[0].value}, ${firstHit.city.default[0].value}, ${firstHit.administrative[0].value}`
        document.getElementById(SELECTORS.searchBar).value = address
        document.getElementById(SELECTORS.locationResults.header).innerHTML = TEMPLATES.locationResultHeader.render({
          name: truncateSearch(document.getElementById(SELECTORS.searchBar).value)
        });
        document.getElementById(SELECTORS.searchBar).disabled = false;
      });

      document.getElementById(SELECTORS.locationResults.body).innerHTML = "";
      doGeoSearch({lat: pos.coords.latitude, lng: pos.coords.longitude});
    }

    function findCurrentLocation() {
      document.getElementById(SELECTORS.searchBar).blur();
      document.getElementById(SELECTORS.searchBar).value = "Getting your location...";
      document.getElementById(SELECTORS.searchBar).disabled = true;
      navigator.geolocation.getCurrentPosition(
          locationHandler
        );
    }

    autocompleteInstance.on("autocomplete:selected", function(event, suggestion, datasetName) {
      if (datasetName == "places") {
        document.getElementById(SELECTORS.locationResults.body).innerHTML = "";
        doGeoSearch(suggestion.latlng);
      }
      if (datasetName == "stops") {
        Turbolinks.visit("/stops/" + suggestion.stop.id);
      }
      if (datasetName == "currentLocation") {
        document.getElementById(SELECTORS.locationResults.body).innerHTML = "";
        document.getElementById(SELECTORS.locationResults.header).innerHTML = "";
        findCurrentLocation();
      }
    });

  }
}
