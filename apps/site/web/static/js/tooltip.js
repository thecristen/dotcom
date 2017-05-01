export default function($) {
  $ = $ || window.jQuery;

  const selector = '[data-toggle="tooltip"]';

  function clearTooltips() {
    $(selector).tooltip('dispose');
  };

  document.addEventListener('turbolinks:before-cache', clearTooltips, {passive: true});
};
