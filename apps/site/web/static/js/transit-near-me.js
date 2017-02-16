export default function($) {
  $ = $ || window.jQuery;
  function setupTNM() {
    if(!$("#place-input").length) {
      return;
    }
    if (typeof google != "undefined") { // only load on pages that are using TNM
      var placeInput = document.getElementById("place-input")
      var autocomplete = new google.maps.places.Autocomplete(placeInput);

      google.maps.event.addListener(autocomplete, 'place_changed', onPlaceChanged);
      $(".transit-near-me form").submit(validateTNMForm);

      function onPlaceChanged() {
        var place = autocomplete.getPlace(),
            loc = window.location,
            location_url = loc.protocol + "//" + loc.host + loc.pathname,
            addr = $(".transit-near-me form").find('input[name="location[address]"]').val();
        if (place.geometry) {
          location_url = "?latitude=" + place.geometry.location.lat() + "&longitude=" + place.geometry.location.lng() + "&location[client_width]=" + ($("#transit-input").width() || 0) + "&location[address]=" + addr +  "#transit-input";
        } else {
          location_url = "?location[address]=" + location_url + place.name + "&location[client_width]=" + ($("#transit-input").width() || 0) + "#transit-input";
        }
        window.location.href = encodeURI(location_url);
      }


      function validateTNMForm($event) {
        var val = $(".transit-near-me form").find('input[name="location[address]"]').val();
        if (val == getUrlParameter('location[address]')) {
          location.reload();
          return false;
        }
        return true;
      }

      var getUrlParameter = function getUrlParameter(sParam) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

        for (i = 0; i < sURLVariables.length; i++) {
          sParameterName = sURLVariables[i].split('=');

          if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
          }
        }
      };
    }
    else {
      const existingCallback = window.mapsCallback || function() {};
      window.mapsCallback = function() {
        window.mapsCallback = undefined;
        existingCallback();
        setupTNM();
      }
    }
  }

  function setClientWidth() {
    $("#client-width").val($("#transit-input").width() || 0);
  }
  window.addEventListener("resize", setClientWidth);
  setClientWidth();

  $(document).on('turbolinks:load', setupTNM);
}
