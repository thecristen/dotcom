export default function() {
  function setupTNM() {
    const placeInput = document.getElementById("tnm-place-input");

    // only load on pages that are using TNM
    if(!placeInput) {
      return;
    }

    placeInput.form.addEventListener('submit', (ev) => validateTNMForm(ev, window.location, placeInput));
  }

  document.addEventListener('turbolinks:load', setupTNM, {passive: true});
  $(document).on('autocomplete:added', '#tnm-place-input', addPlaceChangeCallback)
}

// Functions exported for testing //

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
  return null;
}

// Determines if form should be re-submitted. If place name has not changed
// Do not resubmit the form
// This is done to preserve the names of landmarks
export function validateTNMForm(event, location, placeInput) {
  var val = placeInput.value;
  if (val === getUrlParameter('location[address]', location.search)) {
    event.preventDefault();
    location.reload();
    return false;
  }
  return true;
}

export function constructUrl(place, placeInput) {
  var query_str,
      loc = window.location,
      location_url = loc.protocol + "//" + loc.host + loc.pathname,
      addr = placeInput.value;

  if (place.geometry) {
    var lat = place.geometry.location.lat();
    var lng = place.geometry.location.lng();
    query_str = "?latitude=" + lat + "&longitude=" + lng + "&location[address]=" + addr +  "#transit-input";
  } else {
    query_str = "?location[address]=" + place.name + "#transit-input";
  }
  return location_url + query_str;
}

export function addPlaceChangedEventListener(autocomplete, placeInput) {
  function onPlaceChanged() {
    const locationUrl = constructUrl(autocomplete.getPlace(), placeInput);
    window.location.href = encodeURI(locationUrl);
  }
  google.maps.event.addListener(autocomplete, 'place_changed', onPlaceChanged);
}

function addPlaceChangeCallback(ev, autocomplete){
  addPlaceChangedEventListener(autocomplete, ev.target);
}
