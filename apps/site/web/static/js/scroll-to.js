export default function($) {
  $ = $ || window.jQuery;

  function scrollTo() {
    $("[data-scroll-to]").each(doScrollTo)
      .parents("table").parent().on('scroll', handleScroll);
  }

  function handleScroll(ev) {
    const scrollPos = ev.target.scrollLeft;
    const containerWidth = ev.target.clientWidth;
    const $table = $(ev.target).children("table");
    const width = $table.width();

    $table.toggleClass('hide-earlier', scrollPos < 36)
      .toggleClass('hide-later', width - containerWidth - scrollPos < 36);
  }

  function doScrollTo(index, el) {
    const childLeft = el.offsetLeft;
    const $el = $(el);
    const childWidth = $el.outerWidth();
    const parentLeft = el.parentNode.offsetLeft;
    const firstSiblingWidth = $el.siblings("th").first().outerWidth();
    const timeHeaderWidth = $el.siblings("th").eq(1).outerWidth();

    // set the left position of the time column to be just past the first column
    $el.parents("table").find(".time-column-earlier").css({left: firstSiblingWidth + 'px'});

    // childLeft - parentLeft scrolls the first row to the start of the visible area.
    // we scroll by an additional firstSiblingWidth to get us past the first two column headers.
    const scrollLeft = childLeft - parentLeft- firstSiblingWidth - timeHeaderWidth;
    $(el).parents("table").parent().animate({scrollLeft}, 200);
  }

  $(document).on('turbolinks:load', scrollTo);
}
