export default function init() {
  const $ = window.jQuery;
  const brandPrimary = "#165c96";
  const brandPrimaryLight = "#5da9e8";

  function onFocus(ev) {
    $(ev.target.parentNode).css("borderColor", brandPrimaryLight);
  }

  function onBlur(ev) {
    $(ev.target.parentNode).css("borderColor", brandPrimary);
  }

  $(document).on("focus", ".js-form__input", onFocus);
  $(document).on("blur", ".js-form__input", onBlur);
}
