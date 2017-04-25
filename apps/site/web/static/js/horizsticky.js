export default function($) {
  $ = $ || window.jQuery;

  function bindScrollContainers() {
    $('[data-sticky-container]').each(
      (index, el) => window.requestAnimationFrame(initialPosition.bind(el))
    );
  }

  function initialPosition() {
    const $this = $(this);
    var queue = [];

    $this.find("[data-sticky]")
      .css({width: 'auto', height: 'auto', position: 'relative'}) // reset CSS
      .each((_index, el) => {
        const $child = $(el);
        const sticky = $child.data("sticky");
        const boundingRect = el.getBoundingClientRect();
        const rect = {
          width: Math.ceil(boundingRect.width),
          height: Math.ceil(boundingRect.height)
        };

        if (sticky === "left") {
          queue.push(() => leftSticky($, $child, rect));
        } else if (sticky === "right") {
          queue.push(() => rightSticky($, $child, rect));
        }
      });

    // batch all the CSS updates
    $.each(queue, (_index, fn) => window.requestAnimationFrame(fn));
  }

  $(document).on('turbolinks:load', bindScrollContainers);
  $(window).on('resize', bindScrollContainers);
}

function makeReplacement($, $child) {
  // we add a replacement element so we can push sibling elements out of
  // the way once we've gone absolute
  var $replacement = $child.prev(".sticky-replacement");
  if ($replacement.length === 0) {
    $replacement = $("<" + $child[0].tagName + ">").addClass("sticky-replacement").text(' ');
    $replacement.insertBefore($child);
  }
  return $replacement;
}

function leftSticky($, $child, rect) {
  makeReplacement($, $child)
    .css({
      paddingLeft: rect.width,
      height: rect.height
    });
  // update our CSS position/size
  $child.css({
    height: rect.height,
    width: rect.width,
    left: 0,
    position: 'absolute'
  });
}

function rightSticky($, $child, rect) {
  makeReplacement($, $child)
    .css({
      paddingRight: rect.width,
      height: rect.height
    });

  $child.css({
    height: rect.height,
    width: rect.width,
    right: 0,
    position: 'absolute'
  });
}
