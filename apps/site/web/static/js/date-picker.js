export default function($) {
  $ = $ || window.jQuery;

  // hide the elements
  const hide = () => {
    $('.date-picker-container').attr('hidden', 'hidden');
    $('.calendar-cover').attr('hidden', 'hidden');
  };

  // show the elements
  const show = () => {
    $('.date-picker-container').removeAttr('hidden');
    $('.calendar-cover').removeAttr('hidden');
  };

  // event handler for toggling
  const toggleDatePicker = (ev) => {
    ev.preventDefault();
    if ($('.date-picker-container')[0].hasAttribute('hidden')) {
      show();
    } else {
      hide();
      $('.date-picker-toggle').focus();
    }
  };

  // setup toggle behavior
  const setupDatePicker = () => {
    hide();
    $(document).on('click', '.date-picker-toggle', toggleDatePicker);
  };

  // when the month is shifted, the page will be reloaded, needs to be shown (or re-initialized)
  const displayOnload = () => {
    // don't do anything if the container is not available
    if ($('.date-picker-container').length == 0) {
      return;
    }

    // check if the shift variable is in the query string
    if (window.location.search.match(/shift=[0-9]*/)) {
      // show onload
      show();
    } else {
      // re-initialize the page
      hide();
    }
  }

  // events
  setupDatePicker();
  $(document).on('turbolinks:load', displayOnload);
};
