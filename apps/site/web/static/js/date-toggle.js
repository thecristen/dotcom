export default function($) {
  $ = $ || window.jQuery;

  $(document).on("click", ".date-toggle-edit", (ev) => {
    ev.preventDefault();
    const $el = $(ev.target);
    const $form = $el.parents("form");
    $form.find(".date-toggle").toggleClass("date-toggle-enabled");

    const dateInput = $form.find(".date-toggle-enabled").find("input");
    if (dateInput.length > 0) {
      dateInput.focus();
      window.setTimeout(
        () => dateInput.click(),
        0
      );
    }
  });

  $(document).on("blur", ".date-toggle input", (ev) => {
    ev.preventDefault();
    $(ev.target).parents("form").find(".date-toggle").toggleClass("date-toggle-enabled");
  });
};
