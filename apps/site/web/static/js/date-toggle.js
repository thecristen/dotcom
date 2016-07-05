export default function($) {
  $ = $ || window.jQuery;

  $(".date-toggle-edit").click(function(ev) {
    ev.preventDefault();
    const $form = $(this).parents("form");
    $form.find(".date-toggle").toggleClass("date-toggle-enabled");

    const dateInput = $form.find(".date-toggle-enabled").find("input[type=date]");
    if (dateInput.length > 0) {
      dateInput.focus().click();
    }
  });
};
