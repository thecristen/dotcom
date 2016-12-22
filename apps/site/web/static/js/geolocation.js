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
    loc.href = encodeURI(`${loc.protocol}//${loc.host}${loc.pathname}?location[address]=${location.coords.latitude}, ${location.coords.longitude}#transit-input`);
  };
}

export function locationError($, $btn) {
  return (error) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    if (error.code == error.TIMEOUT || error.code == error.POSITION_UNAVAILABLE) {
      $('#tnm-unavailable-error').removeClass('hidden-xs-up');
    }
    else if (error.code == error.PERMISSION_DENIED) {
      $('.transit-near-me-error').addClass('hidden-xs-up');
      $('#tnm-permission-error').removeClass('hidden-xs-up');
    }
  };
}
