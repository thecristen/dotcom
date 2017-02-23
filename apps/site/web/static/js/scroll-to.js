export default function($) {
  $ = $ || window.jQuery;

  const requestAnimationFrame = window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    function(f) { window.setTimeout(f, 15); };

  function scrollTo() {
    $("[data-scroll-to]").each(doScrollTo);
  }

  function handleScroll(ev) {
    const scrollPos = ev.target.scrollLeft;

    requestAnimationFrame(function() {
      const containerWidth = ev.target.clientWidth;
      const $table = $(ev.target).children();
      const width = $table.width();
      const height = $table.height();

      const hideEarlier = scrollPos < 36;
      const hideLater = width - containerWidth - scrollPos < 36;

      $table
        .toggleClass('schedule-v2-timetable-hide-earlier', hideEarlier)
        .toggleClass('schedule-v2-timetable-hide-later', hideLater)
        .find(".schedule-v2-timetable-time-text:not(.vertically-centered)").each(function(index, textEl) {
          // vertically center the timetable text banners if they're visible
          const $textEl = $(textEl);
          if ($textEl.width()) {
            const top = Math.floor((height - $textEl.height()) / 2);
            $textEl.css({top}).addClass('vertically-centered');
          }
        });
    });
  }

  function doScrollTo(index, el) {
    const childLeft = el.offsetLeft;
    const $el = $(el);
    const childWidth = $el.outerWidth();
    const parentLeft = el.parentNode.offsetLeft;
    const firstSiblingWidth = $el.siblings("th").first().outerWidth();
    const timeHeaderWidth = $el.siblings("th").eq(1).outerWidth();

    // childLeft - parentLeft scrolls the first row to the start of the
    // visible area.  we scroll by an additional firstSiblingWidth and
    // timeHeaderWidth to get us past the first two column headers.
    const scrollLeft = childLeft - parentLeft - firstSiblingWidth - timeHeaderWidth;
    $(el).parents("table").parent()
      .animate({scrollLeft}, 200)
      .on('scroll', handleScroll)
      .trigger('scroll');
  }

  $(document).on('turbolinks:load', scrollTo);
}
