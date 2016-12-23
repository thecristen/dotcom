export default function($ = window.jQuery) {
  if ('geolocation' in navigator) {
    $(document).on('click', '[data-geolocation-target]', clickHandler($));
  }
  else {
    $('html').addClass('geolocation-disabled');
  }
}

// These functions are exported for testing
export function clickHandler($) {
  $(document).on(
    'turbolinks:before-visit', () => {
      $('.loading-indicator').addClass('hidden-xs-up');
      $('.transit-near-me-error').addClass('hidden-xs-up');
    }
  );
  return (event) => {
    event.preventDefault();
    const $btn = $(event.target);
    $btn.find('.loading-indicator').removeClass('hidden-xs-up');
    $('.error-message').addClass('hidden-xs-up');
    navigator.geolocation.getCurrentPosition(
      locationHandler($, $btn, window.location),
      locationError($, $btn)
    );
  };
}

export function locationHandler($, $btn, loc) {
  return (location) => {
    loc.href = encodeURI(`${loc.protocol}//${loc.host}${loc.pathname}?location[address]=${location.coords.latitude}, ${location.coords.longitude}&location[client_width]=${$(".transit-near-me").width()}#transit-input`);
  };
}

export function locationError($, $btn) {
  return (error) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    if (error.code == error.TIMEOUT || error.code == error.POSITION_UNAVAILABLE) {
      $('.transit-near-me-error').addClass('hidden-xs-up');
      $('#tnm-geolocation-error').removeClass('hidden-xs-up');
      $('#tnm-geolocation-error').html("We couldn't fetch your location &mdash; please wait a minute and try again, or enter your address.");
    }
    else if (error.code == error.PERMISSION_DENIED) {
      $('.transit-near-me-error').addClass('hidden-xs-up');
      $('#tnm-geolocation-error').removeClass('hidden-xs-up');
      $('#tnm-geolocation-error').html("It looks like you haven't granted permission to fetch your location &mdash; to use geolocation, update your browser's settings and try again.");
    }
  };
}
