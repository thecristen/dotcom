export default function($) {
  $ = $ || window.jQuery;

  function checkMenuCollapse(ev) {
    // if the focus moves outside the menu and there's still an open menu,
    // click it (which closes it).
    if (ev.relatedTarget && $(ev.relatedTarget).parents("#desktop-menu").length) {
      return;
    }

    $("#desktop-menu [aria-expanded=true]").click();
  }

  $(document).on('focusout', '#desktop-menu', checkMenuCollapse);
}
