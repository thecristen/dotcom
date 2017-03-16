export default function($) {
  $ = $ || window.jQuery;

  function bindScrollContainers() {
    $('[data-sticky-container]').each(initialPosition);
  }

  function initialPosition() {
    const $this = $(this),
          scrollLeft = $this.scrollLeft();
    // reset scroll position
    $this.scrollLeft(0);

    $this.find("[data-sticky=left]").each(function() {
      // reset the width/height of the element
      const $child = $(this).css({width: 'auto', height: 'auto', left: '0px', position: 'relative'});
      // clear a previous sticky replacement
      var $replacement = $child.prev();
      if ($replacement.hasClass("sticky-replacement")) {
        $replacement.remove();
      }
      const rect = this.getBoundingClientRect();
      // we add a replacement element so we can push sibling elements out of
      // the way once we've gone absolute
      $("<" + this.tagName + ">").addClass("sticky-replacement").text(' ')
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
    });
    $this.find("[data-sticky=right]").each(function() {
      const $child = $(this).css({width: 'auto', height: 'auto', right: '0', position: 'relative'});
      const rect = this.getBoundingClientRect();

      $("<" + this.tagName + ">").addClass("sticky-replacement").text(' ')
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
    });

    if (scrollLeft) {
      $(this).scrollLeft(scrollLeft);
    }
  }

  $(document).on('turbolinks:load', bindScrollContainers);
  $(window).on('resize', bindScrollContainers);
}
