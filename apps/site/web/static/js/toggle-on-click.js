export default function($) {
  $ = $ || window.jQuery;

  $(document).on('turbolinks:load', function() {
    $('[subway-collapse]').addClass('collapse');
  });
  $(document).on('click', '[data-toggle-collapse]', function () {
    const route_id = $(this).attr('data-toggle-collapse');
    const toggle_elements = "[data-toggle-route=" + route_id + "]";
    $(toggle_elements).toggle();
  });
};;
