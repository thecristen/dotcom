export default function($) {
  $ = $ || window.jQuery;

  function bindScrollContainers() {
    $('[data-sticky-container]').each(initialPosition);
  }

  function initialPosition() {
    const $this = $(this),
          scrollLeft = $this.scrollLeft();
    var queue = [];
    // reset scroll position
    $this.scrollLeft(0);

    $this.find("[data-sticky]").each(function() {
      // reset the width/height of the element
      const $child = $(this);
      const sticky = $child.data("sticky");
      const rect = {width: $child.outerWidth(), height: $child.outerHeight()};

      if (sticky === "left") {
        queue.push(() => leftSticky($, $child, rect));
      } else if (sticky === "right") {
        queue.push(() => rightSticky($, $child, rect));
      }
    });

    // batch all the CSS updates
    $.each(queue, (_index, fn) => fn());

    if (scrollLeft) {
      $(this).scrollLeft(scrollLeft);
    }
  }

  $(document).on('turbolinks:load', bindScrollContainers);
  $(window).on('resize', bindScrollContainers);
}

function maybeReplace($child) {
  // clear a previous sticky replacement
  var $replacement = $child.prev();
  if ($replacement.hasClass("sticky-replacement")) {
    $replacement.remove();
  }
}

function leftSticky($, $child, rect) {
  maybeReplace($child);
  // we add a replacement element so we can push sibling elements out of
  // the way once we've gone absolute
  $("<" + $child[0].tagName + ">").addClass("sticky-replacement").text(' ')
    .css({
      paddingLeft: Math.ceil(rect.width),
      height: Math.ceil(rect.height)
    })
    .insertBefore($child);
  // update our CSS position/size
  $child.css({
    height: Math.ceil(rect.height),
    width: Math.ceil(rect.width),
    left: 0,
    position: 'absolute'
  });
}

function rightSticky($, $child, rect) {
  maybeReplace($child);
  $("<" + $child[0].tagName + ">").addClass("sticky-replacement").text(' ')
    .css({
      paddingRight: Math.ceil(rect.width),
      height: Math.ceil(rect.height)
    })
    .insertBefore($child);

  $child.css({
    height: Math.ceil(rect.height),
    width: Math.ceil(rect.width),
    right: 0,
    position: 'absolute'
  });
}
