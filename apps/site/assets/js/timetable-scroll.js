export default $ => {
  $ = $ || window.jQuery;

  const scroll = direction => {
    // determine the scrolling increment based on the width of an existing column
    const offset = $(".schedule-timetable-header-col.schedule-timetable-time-col").eq(0).outerWidth() * direction;

    // find the container element that will be scrolled
    const $el = $("[data-sticky-container]");

    // animate the scroll event
    $el.animate({scrollLeft: $el.scrollLeft() + offset});
  };

  $(document).on("click", "button[data-scroll='earlier']", _ev => scroll(-1));
  $(document).on("click", "button[data-scroll='later']", _ev => scroll(1));
};
