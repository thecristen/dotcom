export default function($) {
  $ = $ || window.jQuery;
  function initMap() {
    if(!$("#map").length) {
      return;
    }
    if (typeof google != "undefined") {
      $("#map").addClass("google-map");
      $("#static-map").hide();
      var lat = parseFloat($("#map").attr("data-latitude"));
      var lng = parseFloat($("#map").attr("data-longitude"));
      var isStation = $("#map").attr("data-show-marker") == 'true';
      displayMap(lat, lng, isStation);
    }

    else {
      const existingCallback = window.mapsCallback || function() {};
      window.mapsCallback = function() {
        window.mapsCallback = undefined;
        existingCallback();
        initMap();
      }
    }
  }

  $(document).on('turbolinks:load', initMap);
}

function displayMap(lat, lng, showMarker) {
  var latLng = {lat: lat, lng: lng}
  var map = new google.maps.Map(document.getElementById('map'), {
    zoom: 17,
    center: latLng,
    gestureHandling: 'cooperative'
  });
  var noPoi = [ // Don't show points of interest
    {
      featureType: "poi",
        stylers: [
          { visibility: "off" }
        ]   
    }
  ];
  map.setOptions({styles: noPoi});
  if (!showMarker) { // Only show map marker for bus stops
    var marker = new google.maps.Marker({
      position: latLng,
      map: map
    });
  }
}
