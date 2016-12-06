export default function($ = window.jQuery) {
  const $locateBtn = $("[data-geolocation-target]");
  if ("geolocation" in navigator) {
    $locateBtn.click(clickHandler($));
  }
  else {
    $locateBtn.hide();
  }
}

// These functions are exported for testing
export function clickHandler($) {
  return (event) => {
    event.preventDefault();
    const $btn = $(event.target);
    $btn.find('.loading-indicator').removeClass('hidden-xs-up');
    $('.service-near-me-error').addClass('hidden-xs-up');
    navigator.geolocation.getCurrentPosition(
      locationHandler($, $btn),
      locationError($, $btn)
    );
  };
}

export function locationHandler($, $btn) {
  return (location) => {
    const $input = $(`#${$btn.data('geolocation-target')}`);
    $input.val(`${location.coords.latitude}, ${location.coords.longitude}`);
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    $input.parents('form').submit();
  };
}

export function locationError($, $btn) {
  return (error) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    if (error.code == error.TIMEOUT || error.code == error.POSITION_UNAVAILABLE) {
      $('.service-near-me-error').removeClass('hidden-xs-up');
    }
  };
}
