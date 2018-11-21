export default $ => {
  $ = $ || window.jQuery;

  const scroll = direction => {
    // determine the scrolling increment based on the width of an existing column
    // get the second column (the first is a header) and add 1 for the border
    const offset =
      ([...document.querySelectorAll(".js-tt-cell")].slice(1, 2)[0]
        .clientWidth +
        1) *
      direction;

    // find the container element that will be scrolled
    const $el = $("[data-sticky-container]");

    // animate the scroll event
    $el.animate({ scrollLeft: $el.scrollLeft() + offset });
  };

  $(document).on("click", "button[data-scroll='earlier']", _ev => scroll(-1));
  $(document).on("click", "button[data-scroll='later']", _ev => scroll(1));
};
