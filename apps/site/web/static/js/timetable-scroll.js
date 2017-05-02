export default function($) {
  $ = $ || window.jQuery;

  function setupTimetableScroll() {
    $(document).on(
      'click', '.schedule-v2-timetable-more-col-earlier',
      function(ev) { $(ev.target).closest('[data-sticky-container]')[0].scrollLeft -= 100;});
    $(document).on(
      'click', '.schedule-v2-timetable-more-col-later',
      function(ev) { $(ev.target).closest('[data-sticky-container]')[0].scrollLeft += 100;});
  }

  setupTimetableScroll();
};
