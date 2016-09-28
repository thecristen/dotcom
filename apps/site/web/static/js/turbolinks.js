export default function($) {
  $ = $ || window.jQuery;

  var savedPosition = null;

  Turbolinks.start();
  $(document).on('turbolinks:before-visit', (ev) => {
    const url = ev.originalEvent.data.url;
    const anchorIndex = url.indexOf('#');
    if (anchorIndex !== -1) {
      ev.preventDefault();
      ev.stopPropagation();
      const newUrl = url.slice(0, anchorIndex);
      window.setTimeout(() => Turbolinks.visit(newUrl), 0);
      return;
    }
    const currentPath = `${window.location.protocol}//${window.location.host}${window.location.pathname}`;
    if (samePath(url, currentPath)) {
      savedPosition = [window.scrollX, window.scrollY];
    }

  });
  $(document).on('turbolinks:render', (ev) => {
    if (savedPosition) {
      window.scrollTo.apply(window, savedPosition);
      savedPosition = null;
    }
  });
};

export function samePath(first, second) {
  return (first.slice(0, second.length) === second && (
    first.length == second.length || first[second.length] === "?"));
};
