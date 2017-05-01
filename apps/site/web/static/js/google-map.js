export default function($) {
  $ = $ || window.jQuery;
  function initMap() {
    const map = document.getElementById("map");
    if(!map) {
      return;
    }
    initializeMap(map);
  }

  document.addEventListener('turbolinks:load', initMap, {passive: true});
}

function initializeMap(map) {
  if (typeof google != "undefined") {
    map.className += "google-map";
    document.getElementById("static-map").style.display = "none";
    const lat = parseFloat(map.getAttribute("data-latitude"));
    const lng = parseFloat(map.getAttribute("data-longitude"));
    const isStation = map.getAttribute("data-show-marker") == 'true';
    displayMap(map, lat, lng, isStation);
  }

  else {
    const existingCallback = window.mapsCallback || function() {};
    window.mapsCallback = function() {
      window.mapsCallback = undefined;
      existingCallback();
      initializeMap(map);
    };
  }
}

function displayMap(el, lat, lng, showMarker) {
  const latLng = {lat: lat, lng: lng};
  const map = new google.maps.Map(el, {
    zoom: 17,
    center: latLng,
    gestureHandling: 'cooperative'
  });
  const noPoi = [ // Don't show points of interest
    {
      featureType: "poi",
        stylers: [
          { visibility: "off" }
        ]
    }
  ];
  map.setOptions({styles: noPoi});
  if (!showMarker) { // Only show map marker for bus stops
    const marker = new google.maps.Marker({
      position: latLng,
      map: map
    });
  }
}
