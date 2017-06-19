export default function($) {
  $ = $ || window.jQuery;

  const scroll = (ev, direction) => {
    // determine the scrolling increment based on the width of an existing column
    const offset = $(".schedule-v2-timetable-header-col.schedule-v2-timetable-time-col").eq(0).outerWidth() * direction;

    // find the container element that will be scrolled
    const $el = $(ev.target).closest("[data-sticky-container]");

    // animate the scroll event
    $el.animate({scrollLeft: $el.scrollLeft() + offset});
  };

  function addClickHandlers() {
    $(document).on("click", ".schedule-v2-timetable-more-col-earlier", (ev) => { scroll(ev, -1); });
    $(document).on("click", ".schedule-v2-timetable-more-col-later", (ev) => { scroll(ev, 1); });
  }

  addClickHandlers();
};
