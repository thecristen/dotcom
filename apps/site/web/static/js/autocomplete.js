export default function() {
  document.addEventListener('turbolinks:load', setupAutocomplete, {passive: true});
}

function setupAutocomplete() {
  if($('[data-autocomplete=true]').length > 0) {
    if (typeof google !== "undefined") {
      $('[data-autocomplete=true]').each(function(idx, input) {
        var autocomplete = new google.maps.places.Autocomplete(input);
        $(input).trigger('autocomplete:added', autocomplete);
      });
    }
    else {
      const existingCallback = window.mapsCallback || function() {};
      window.mapsCallback = function() {
        window.mapsCallback = undefined;
        existingCallback();
        setupAutocomplete();
      };
    }
  }
}
