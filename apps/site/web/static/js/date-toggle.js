module.exports = function($) {
  $(".date-toggle-edit").click(function(ev) {
    ev.preventDefault();
    const $form = $(this).parents("form");
    const dateInput = $form.find(".date-toggle-enabled").find("input[type=date]");

    $form.find(".date-toggle").toggleClass("date-toggle-enabled");
    if (dateInput.length > 0) {
      dateInput.click().focus().click();
    }
  });
};
