export default function($) {
  $ = $ || window.jQuery;

  function setupTimetableScroll() {
    $(document).on('click', '[data-sticky=right]', function(ev) { $(ev.target).closest('[data-sticky-container]').get(0).scrollLeft += 100;});
    $(document).on('click', '[data-sticky=left]', function(ev) { $(ev.target).closest('[data-sticky-container]').get(0).scrollLeft -= 100;});
  }

  setupTimetableScroll();
};
