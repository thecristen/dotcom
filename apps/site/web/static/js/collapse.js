export default function($) {
  $ = $ || window.jQuery;

  function handler(extraClass, collapseEvent) {
    return function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      const selector = $(ev.currentTarget).data('target');
      $(selector)
        .addClass('collapse')
        .addClass(extraClass)
        .collapse({toggle: false})
        .collapse(collapseEvent);
    };
  }
  $(document).on('click', '[data-hide=collapse]', handler('in', 'hide'));
  $(document).on('click', '[data-show=collapse]', handler('', 'show'));
};
