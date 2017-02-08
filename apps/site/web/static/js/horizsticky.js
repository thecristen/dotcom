export default function($) {
  $ = $ || window.jQuery;

  const requestAnimationFrame = window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    function(f) { window.setTimeout(f, 15); };

  function bindScrollContainers() {
    $('[data-sticky-container]').on('scroll', onScroll)
      .trigger('scroll');
  }

  const waitingFor = {};

  function onScroll(ev) {
    if (waitingFor[ev.target]) {
      return;
    }
    waitingFor[ev.target] = true;
    requestAnimationFrame(function() { reposition(ev.target); });
  }

  function reposition(parentEl) {
    delete waitingFor[parentEl];
    const $parent = $(parentEl),
          parentWidth = $parent.width(),
          childWidth = $parent.children().first().width(),
          offset = $parent.scrollLeft();

    $parent.find("[data-sticky]").each(function(_index, el) {
      const $el = $(el),
            sticky = $el.data("sticky");
      var needsScroll = $el.data("horizsticky-enabled");
      if (!needsScroll && offset !== 0) {
        needsScroll = true;
        $el.data("horizsticky-enabled", true);
      }

      if (needsScroll) {
        if (sticky === "left") {
          // once we scroll, we can be off by a pixel.  move left 1 pixel so
          // no content appears to the left.
          const newLeft = Math.max(offset - 1, 0);
          $el.css({position: "relative", left: newLeft});
        } else if (sticky === "right") {
          const newRight = childWidth - parentWidth - offset;
          $el.css({position: "relative", right: newRight});
        }
      }
    });
  }

  $(document).on('turbolinks:load', bindScrollContainers);
}
