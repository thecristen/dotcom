export default function search($ = window.jQuery) {
  // focus the search input once the menu is fully expanded
  $(document).on("shown.bs.collapse", "#search", (ev) => {
    $(".search-dropdown input").focus();
  });
};
