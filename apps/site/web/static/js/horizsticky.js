export default function($) {
  $ = $ || window.jQuery;

  const requestAnimationFrame = window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    function(f) { window.setTimeout(f, 15); };

  function bindScrollContainers() {
    $('[data-sticky-container]').on('scroll', onScroll);
    triggerScrollContainers();
  }

  function triggerScrollContainers() {
    $('[data-sticky-container]').trigger('scroll');
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
      if (sticky === "left") {
        // once we scroll, we can be off by a pixel.  move left 1 pixel so
        // no content appears to the left.
        const newLeft = Math.max(offset - 1, 0);
        $el.css({position: "relative", left: newLeft});
      } else if (sticky === "right") {
        const newRight = childWidth - parentWidth - offset;
        $el.css({position: "relative", right: newRight});
      }
    });
  }

  $(document).on('turbolinks:load', bindScrollContainers);
  $(window).on('resize', triggerScrollContainers);
}
