export default function($) {
  $ = $ || window.jQuery;
  function setupTNM() {
    const placeInput = document.getElementById("place-input");
    if(!placeInput) {
      return;
    }
    if (typeof google != "undefined") { // only load on pages that are using TNM
      var autocomplete = new google.maps.places.Autocomplete(placeInput);

      function onPlaceChanged() {
        setClientWidth($);
        const locationUrl = constructUrl(autocomplete.getPlace(), $);
        window.location.href = encodeURI(locationUrl);
      }

      google.maps.event.addListener(autocomplete, 'place_changed', onPlaceChanged);
      $(".transit-near-me form").submit((ev) => submitTNMForm(ev, window.location, $));

    }
    else {
      const existingCallback = window.mapsCallback || function() {};
      window.mapsCallback = function() {
        window.mapsCallback = undefined;
        existingCallback();
        setupTNM();
      };
    }
  }

  document.addEventListener('turbolinks:load', setupTNM, {passive: true});
}

// Functions exported for testing //

export function setClientWidth($) {
  $("#client-width").val($("#transit-input").width() || 0);
}

export function getUrlParameter(sParam, search_string) {
  var sPageURL = decodeURIComponent(search_string.substring(1)),
    sURLVariables = sPageURL.split('&'),
    sParameterName,
    i;

  for (i = 0; i < sURLVariables.length; i++) {
    sParameterName = sURLVariables[i].split('=');

    if (sParameterName[0] === sParam) {
      return sParameterName[1] === undefined ? true : sParameterName[1];
    }
  }
}

export function submitTNMForm($event, location, $) {
  setClientWidth($);
  return validateTNMForm($event, location, $);
}

// Determines if form should be re-submitted. If place name has not changed
// Do not resubmit the form
// This is done to preserve the names of landmarks
export function validateTNMForm($event, location, $) {
  var val = $(".transit-near-me form").find('input[name="location[address]"]').val();
  if (val == getUrlParameter('location[address]', location.search)) {
    location.reload();
    return false;
  }
  return true;
}

export function constructUrl(place, $) {
  var query_str,
      loc = window.location,
      location_url = loc.protocol + "//" + loc.host + loc.pathname,
      addr = $(".transit-near-me form").find('input[name="location[address]"]').val(),
      width = ($("#client-width").val() || 0);

  if (place.geometry) {
    var lat = place.geometry.location.lat();
    var lng = place.geometry.location.lng();
    query_str = "?latitude=" + lat + "&longitude=" + lng + "&location[client_width]=" + width + "&location[address]=" + addr +  "#transit-input";
  } else {
    query_str = "?location[address]=" + place.name + "&location[client_width]=" + width + "#transit-input";
  }
  return location_url + query_str;
}
