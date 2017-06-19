export default function($) {
  $ = $ || window.jQuery;

  const scroll = (ev) => {
    // determine scroll direction based on element clicked
    var multiplier;
    var $boundEl = $(ev.target);
    while (true) {
      if (!$boundEl || $boundEl.hasClass("schedule-v2-timetable-more-col")) {
        multiplier = ($boundEl.hasClass("schedule-v2-timetable-more-col-earlier")) ? -1 : 1;
        break;
      }
      $boundEl = $boundEl.parent();
    }

    // dynamically determine width of column based on width of an existing column
    const offset = $(".schedule-v2-timetable-header-col.schedule-v2-timetable-time-col").eq(0).outerWidth() * multiplier;

    // find the container element to be scrolled
    const $el = $(ev.target).closest("[data-sticky-container]");

    // animate the scroll element
    $el.animate({scrollLeft: $el.scrollLeft() + offset});
  };

  function addClickHandlers() {
    $(document).on("click", ".schedule-v2-timetable-more-col-earlier", scroll);
    $(document).on("click", ".schedule-v2-timetable-more-col-later", scroll);
  }

  addClickHandlers();
};
