export default function ($) {
  $ = $ || window.jQuery;

  window.mapsCallback = function() {
    window.googleMapsLoaded = true;
    $(document).trigger("google-maps:loaded");
  }
}

export function doWhenGoogleMapsIsLoaded ($, callback) {
  window.googleMapsLoaded ? callback() : $(document).on("google-maps:loaded", () => callback());
}
