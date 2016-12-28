export default function() {
  function setupTNM() {
    if (typeof google != "undefined") { // only load on pages that are using TNM
      window.addEventListener("resize", set_client_width);
      set_client_width();
      var autocomplete = new google.maps.places.Autocomplete(document.getElementById("place-input"));
      google.maps.event.addListener(autocomplete, 'place_changed', onPlaceChanged);
      $(".transit-near-me form").submit(validateTNMForm)

        function onPlaceChanged() {
          var place = autocomplete.getPlace(),
          loc = window.location,
          location_url = loc.protocol + "//" + loc.host + loc.pathname + "?location[address]=",
          addr = $(".transit-near-me form").find('input[name="location[address]"]').val();
          if (place.geometry) {
            location_url = location_url + place.geometry.location.lat() + ", " + place.geometry.location.lng() + "&location[client_width]=" + ($("#transit-input").width() || 0) + "&place_name=" + addr +  "#transit-input";
          } else {
            location_url = location_url + place.name + "&location[client_width]=" + ($("#transit-input").width() || 0) + "#transit-input";
          }
          window.location.href = encodeURI(location_url);
        }

      function set_client_width() {
        $("#client-width").val($("#transit-input").width() || 0);
      }

      function validateTNMForm($event) {
        var val = $(".transit-near-me form").find('input[name="location[address]"]').val();
        if (val == getUrlParameter('place_name')) {
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
  }
  $(document).on("ready", setupTNM);

}
