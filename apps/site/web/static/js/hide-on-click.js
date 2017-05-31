export default function($) {
  $ = $ || window.jQuery;

  $(document).on('click', '[data-hide-on-click]', function () {
    $(this).hide();
  });
};
