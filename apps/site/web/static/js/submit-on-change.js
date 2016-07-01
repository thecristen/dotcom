module.exports = function($) {
  $("[data-submit-on-change]").each(
    function() {
      const $this = $(this);
      const onChange = function(e) {
        $(this).parents("form").submit();
      };
      $this.find("select").change(onChange);
      $this.find("input").change(onChange);
      $this.find("[type=submit]").hide();
    }
  );
};
