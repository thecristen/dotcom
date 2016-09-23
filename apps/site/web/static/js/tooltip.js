export default function($) {
  $ = $ || window.jQuery;

  function addTooltips() {
    $('[data-toggle="tooltip"]').tooltip();
  };
  function clearTooltips() {
    $(".tooltip.in").remove();
  };

  addTooltips();
  $(document).on('turbolinks:load', addTooltips);
  $(document).on('turbolinks:before-cache', clearTooltips);
};
