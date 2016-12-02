export default function($) {
  $ = $ || window.jQuery;

  function setupCarousel() {
    $(".carousel").each((_index, carousel) => {
      $(carousel).on("click", ".carousel-item", (ev) => {
        ev.preventDefault();
        const $item = $(ev.currentTarget);
        const $target = $(ev.delegateTarget.getAttribute("data-target"));
        $target.html($item.html());
      })
        .find(".carousel-item:first-child")
        .click();
    });
  }
  $(document).on('turbolinks:load', setupCarousel);
};
