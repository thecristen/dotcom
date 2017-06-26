export default function($ = window.jQuery, doc = document, navigator = window.navigator) {
  if ('geolocation' in navigator) {
    doc.addEventListener(
      'turbolinks:before-visit', beforeVisit($),
      {passive: true}
    );
    $(document).on('click', '[data-geolocation-target]', clickHandler($));
  } else {
    doc.documentElement.className += " geolocation-disabled";
  }
}

function beforeVisit($) {
  return () => {
    $('.loading-indicator, .location-error').hide();
  };
};

// These functions are exported for testing
export function clickHandler($) {
  return (event) => {
    event.preventDefault();
    const $btn = $(event.target);
    const $errorEl = $('#' + $btn.data("id") + '-geolocation-error');
    $btn.find('.loading-indicator').removeClass('hidden-xs-up');
    $errorEl.addClass('hidden-xs-up');
    navigator.geolocation.getCurrentPosition(
      locationHandler($, $btn, $errorEl),
      locationError($, $btn, $errorEl)
    );
  };
}

export function locationHandler($, $btn, $errorEl) {
  return (location) => {
    const id = $btn.data("id");
    const field = $btn.data("field");
    $("#" + id).trigger('geolocation:complete', location);
  };
}

export function locationError($, $btn, $errorEl) {
  return (error) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    if (error.code == error.TIMEOUT || error.code == error.POSITION_UNAVAILABLE) {
      $errorEl.removeClass('hidden-xs-up');
      $errorEl.html("We couldn't fetch your location &mdash; please wait a minute and try again, or enter your address.");
    } else if (error.code == error.PERMISSION_DENIED) {
      $errorEl.removeClass('hidden-xs-up');
      $errorEl.html("It looks like you haven't granted permission to fetch your location &mdash; to use geolocation, update your browser's settings and try again.");
    }
  };
}
