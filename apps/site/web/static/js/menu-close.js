export default function($) {
  $ = $ || window.jQuery;

  function checkMenuCollapse(ev) {
    // if the focus moves outside the menu and there's still an open menu,
    // click it (which closes it).
    if (!$(ev.target).parents("#desktop-menu").length) {
      $("#desktop-menu [aria-expanded=true]").click();
    }
  }

  $(document).on('focusin', 'body', checkMenuCollapse);
}
