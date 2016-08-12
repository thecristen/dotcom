export default function(events, $) {
  $ = $ || window.jQuery;
  events.forEach((event) => {
    $("[data-submit-on-" + event + "]").each((index, el) => {
      const $el = $(el);
      function onEvent() {
        $(this).siblings('label').find('.loading-indicator').removeClass('hidden-xs-up');
        $(this).parents("form").submit();
      };
      $el.find("select")[event](onEvent);
      $el.find("input")[event](onEvent);
      $el.find("[type=submit]").hide();
    });
  });
};
