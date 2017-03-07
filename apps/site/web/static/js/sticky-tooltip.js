// Sourced from https://gist.github.com/alekseyg/d2261e42a9b5335a8ce0774b4d92f129 with small
// modifications. Fixes being unable to dismiss tooltips on iOS devices.

export default function ($) {
  $ = $ || window.jQuery;

  const wasTapped = (element) => {
    const touchStart = element.data('lastTouchStart');
    const touchEnd = element.data('lastTouchEnd');
    return (
      touchStart && touchEnd &&
      touchEnd.timeStamp - touchStart.timeStamp <= 500 &&   // duration
      Math.abs(touchEnd.pageX - touchStart.pageX) <= 10 &&  // deltaX
      Math.abs(touchEnd.pageY - touchStart.pageY) <= 10     // deltaY
    );
  };

  const wasTouchedRecently = (element) => {
    const lastTouch = element.data('lastTouchEnd') || element.data('lastTouchStart');
    return lastTouch && new Date() - lastTouch.timeStamp <= 550;
  };

  const hideTooltip = (element) => {
    window.setTimeout(() => {
      element.tooltip('hide');
    }, 10);
  };

  const initTooltip = () => {
    $('[data-toggle="tooltip"]').tooltip({trigger: 'manual'})
    .on('touchstart', function (e) {
      $(this).data('lastTouchStart', e.originalEvent);
    })
    .on('touchend', function (e) {
      const $this = $(this);
      $this.data('lastTouchEnd', e.originalEvent);

      if (wasTapped($this)) {
        $this.tooltip('toggle');
      }
    })
    .on('mouseenter', function (e) {
      const $this = $(this);
      if (wasTouchedRecently($this)) {
        return;
      }

      $this.tooltip('show');
    })
    .on('mouseleave', function (e) {
      const $this = $(this);
      if (wasTouchedRecently($this)) {
        return;
      }

      hideTooltip($this);
    })

    $('body').on('touchend', (e) => {
      hideTooltip($('[data-toggle="tooltip"]'));
    })
    $('[data-toggle="tooltip"]').on('touchend', (e) => {
      e.stopPropagation();
    })
  };

  $(initTooltip);
};
