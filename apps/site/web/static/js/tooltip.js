export default function($) {
  $ = $ || window.jQuery;

  const selector = '[data-toggle="tooltip"]';

  function addTooltips() {
    $(selector).tooltip();
  };
  function clearTooltips() {
    $(selector).tooltip('dispose');
  };

  $(document).on('turbolinks:load', addTooltips);
  $(document).on('turbolinks:before-cache', clearTooltips);
};
