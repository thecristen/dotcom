export default function($) {
  $ = $ || window.jQuery;

  const selector = '[data-toggle="tooltip"]';

  function clearTooltips() {
    $(selector).tooltip('dispose');
  };

  $(document).on('turbolinks:before-cache', clearTooltips);
};
