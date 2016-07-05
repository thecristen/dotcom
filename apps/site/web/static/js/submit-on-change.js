export default function($) {
  $ = $ || window.jQuery;
  $("[data-submit-on-change]").each((index, el) => {
    const $el = $(el);
    function onChange() {
      $(this).parents("form").submit();
    };
    $el.find("select").change(onChange);
    $el.find("input").change(onChange);
    $el.find("[type=submit]").hide();
  });
};
