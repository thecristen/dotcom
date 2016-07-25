export default function($) {
  $ = $ || window.jQuery;

  $(".date-toggle-edit").click(function(ev) {
    ev.preventDefault();
    const $form = $(this).parents("form");
    $form.find(".date-toggle").toggleClass("date-toggle-enabled");

    const dateInput = $form.find(".date-toggle-enabled").find("input");
    if (dateInput.length > 0) {
      window.setTimeout(
        () => {dateInput.focus().click();},
        0);
    }
  });

  $(".date-toggle input").blur(function (ev) {
    ev.preventDefault();
    $(this).parents("form").find(".date-toggle").toggleClass("date-toggle-enabled");
  });
};
