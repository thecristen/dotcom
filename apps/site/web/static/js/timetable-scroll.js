export default function($) {
  $ = $ || window.jQuery;

  // multiplier argument effects wether the scroll is negative or positive (left or right)
  const scroll = (ev, multiplier) => {
    // dynamically determine width of column based on width of an existing column
    const offset = $(".schedule-v2-timetable-header-col.schedule-v2-timetable-time-col").eq(0).outerWidth() * multiplier;

    // find the container element to be scrolled
    const $el = $(ev.target).closest("[data-sticky-container]");

    // animate the scroll element
    $el.animate({scrollLeft: $el.scrollLeft() + offset});
  };

  function addClickHandlers() {
    $(document).on("click", ".schedule-v2-timetable-more-col-earlier", (ev) => { scroll(ev, -1); });
    $(document).on("click", ".schedule-v2-timetable-more-col-later", (ev) => { scroll(ev, 1); });
  }

  addClickHandlers();
};
