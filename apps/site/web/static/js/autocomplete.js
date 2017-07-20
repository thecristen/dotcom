export default function() {
  function setup() {
    document.addEventListener('turbolinks:load', setupAutocomplete, {passive: true});
  }
  if (typeof google !== "undefined") {
    setup();
    return;
  }
  const existingCallback = window.mapsCallback || function() {};
  window.mapsCallback = function() {
    window.mapsCallback = undefined;
    existingCallback();
    setup();
    // we need to call the setupAutocomplete() as well, since this will be
    // after the turbolinks:load call
    setupAutocomplete();
  };
}

function setupAutocomplete() {
  const $elements = $('[data-autocomplete=true]');
  if($elements.length > 0) {
    // these are the same bounds we use for OpenTripPlanner
    const mbtaWatershedBounds = new google.maps.LatLngBounds(
      new google.maps.LatLng(41.3193, -71.9380),
      new google.maps.LatLng(42.8266, -69.6189)
    );
    const options = {
      strictBounds: true,
      bounds: mbtaWatershedBounds
    };
    $elements.each(function(idx, input) {
      const autocomplete = new google.maps.places.Autocomplete(input, options);
      $(input).trigger('autocomplete:added', autocomplete);
    });
  }
}
