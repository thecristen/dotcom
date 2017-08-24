import { doWhenGooleMapsIsReady } from './google-maps-loaded';

export default function() {
  doWhenGooleMapsIsReady(() => {
    document.addEventListener('turbolinks:load', setupAutocomplete, {passive: true});
    setupAutocomplete();
  });
}

function setupAutocomplete() {
  const $elements = $("[data-autocomplete=true]");

  // do nothing if there are no autocomplete elements on the page
  if ($elements.length == 0) {
    return;
  }

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
    $(input).trigger("autocomplete:added", autocomplete);
  });
}
