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
  return (event) => {
    event.preventDefault();
    const $btn = $(event.target);
    $btn.find('.loading-indicator').removeClass('hidden-xs-up');
    $('.transit-near-me-error').addClass('hidden-xs-up');
    navigator.geolocation.getCurrentPosition(
      locationHandler($, $btn),
      locationError($, $btn)
    );
  };
}

export function locationHandler($, $btn) {
  return (location) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    const loc = window.location;
    window.Turbolinks.visit(encodeURI(`${loc.protocol}//${loc.host}${loc.pathname}?location[address]=${location.coords.latitude}, ${location.coords.longitude}#transit-input`));
  };
}

export function locationError($, $btn) {
  return (error) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    if (error.code == error.TIMEOUT || error.code == error.POSITION_UNAVAILABLE) {
      $('.transit-near-me-error').removeClass('hidden-xs-up');
    }
  };
}
