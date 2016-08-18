export default function($) {
  $ = $ || window.jQuery;

  function addTooltips() {
    $('[data-toggle="tooltip"]').tooltip();
  };
  addTooltips();
  $(document).on('turbolinks:load', addTooltips);
};
