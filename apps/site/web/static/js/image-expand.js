export default function($) {
  $ = $ || window.jQuery;
  $(document).on("click", ".expandable", (ev) => {
    const $el = $(ev.target);
    $el.toggleClass('expanded') ;
  });
};
