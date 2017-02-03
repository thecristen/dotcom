export default function($) {
  $ = $ || window.jQuery;

  function scrollTo() {
    $("[data-scroll-to]").each(doScrollTo);
  }

  function doScrollTo(index, el) {
    const childLeft = el.offsetLeft;
    const $el = $(el);
    const childWidth = $el.outerWidth();
    const parentLeft = el.parentNode.offsetLeft;
    const firstSiblingWidth = $el.siblings("th").first().outerWidth();

    // childLeft - parentLeft scrolls the first row to the start of the visible area.
    // we scroll by an additional firstSiblingWidth to get us past the first-column headers.
    $(el).parents("table").parent().scrollLeft(childLeft
                                               - parentLeft
                                               - firstSiblingWidth);
  }

  $(document).on('turbolinks:load', scrollTo);
}
