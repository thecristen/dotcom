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
            location_url = loc.protocol + "//" + loc.host + loc.pathname + "?location[address]=";
        if (place.geometry) {
          location_url = location_url + place.geometry.location.lat() + ", " + place.geometry.location.lng() + "&location[client_width]=" + ($("#transit-input").width() || 0) + "#transit-input";
        } else {
          location_url = location_url + place.name + "&location[client_width]=" + ($("#transit-input").width() || 0) + "#transit-input";
        }
        window.location.href = encodeURI(location_url);
      }

      function set_client_width() {
        $("#client-width").val($("#transit-input").width() || 0);
      }

      function validateTNMForm($event) {
        const data = $($event.target).data()
        if (data.place_name && $event.target.value && $event.target.value == data.place_name) {
          location.reload();
          return false;
        }
        return true;
      }
    }
  }
  $(document).on("ready", setupTNM);

}
