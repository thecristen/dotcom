export default function($) {
  $ = $ || window.jQuery;

  var savedPosition = null;
  var savedAnchor = null;
  var redirectTimeout = null;

  window.addEventListener('popstate', (ev) => {
    var url = window.location.href;

    if (redirectTimeout && !url.match(/redirect/)) {
      clearTimeout(redirectTimeout);
      redirectTimeout = null;
    }
  }, {passive: true});
  document.addEventListener('turbolinks:before-visit', (ev) => {
    const url = ev.data.url;
    const anchorIndex = url.indexOf('#');
    const currentPath = `${window.location.protocol}//${window.location.host}${window.location.pathname}`;
    if (anchorIndex !== -1) {
      const newUrl = url.slice(0, anchorIndex);
      if (!samePath(`${currentPath}${window.location.search}`, newUrl)) {
        ev.preventDefault();
        ev.stopPropagation();
        savedAnchor = url.slice(anchorIndex, url.length);
        window.setTimeout(() => Turbolinks.visit(newUrl), 0);
      }
      return;
    }

    if (samePath(url, currentPath)) {
      savedPosition = [window.scrollX, window.scrollY];
    }

    // cancel a previously set redirect timeout
    if (redirectTimeout) {
      clearTimeout(redirectTimeout);
      redirectTimeout = null;
    }

  });
  document.addEventListener('turbolinks:render', (ev) => {
    // if it's cached render, not a real one, set the scroll/focus positions,
    // but don't clear them until we have the true rendering.
    var clearSaved = $('html').attr('data-turbolinks-preview') !== '';
    if (savedPosition) {
      window.scrollTo.apply(window, savedPosition);
      if (clearSaved) {
        savedPosition = null;
      }
    }
    if (savedAnchor) {
      // if we saved the anchor and it's above the screen, scroll to it
      const $el = $(savedAnchor);
      const $window = $(window);
      if (clearSaved) {
        savedAnchor = null;
      }
      if ($el.length > 0) {
        const nodeName = $el[0].nodeName;
        const elementY = $el.offset().top;
        const windowY = $window.scrollTop();
        if (windowY > elementY) {
          $window.scrollTop(elementY - 20);
        }
        // if we're focusing a link, then focus it directly. otherwise, find
        // the first child link and focus that.
        if (nodeName === "A" || nodeName === "SELECT" || nodeName === "INPUT") {
          $el.focus();
        } else {
          $el.find('a:first').focus();
        }
      }
    }
  }, {passive: true});
  document.addEventListener('turbolinks:request-end', (ev) => {
    // if a refresh header was receieved, enforce via javascript
    var refreshHeader = ev.data.xhr.getResponseHeader("Refresh");
    if (!refreshHeader) {
      return;
    }

    // parse data from the header
    var refreshUrl = refreshHeader.substring(refreshHeader.indexOf('=') + 1);
    var refreshDelay = refreshHeader.split(';')[0] * 1000;

    // redirect after 5 seconds
    redirectTimeout = setTimeout(function () {
      document.location = refreshUrl;
    }, refreshDelay);
  }, {passive: true});
};

export function samePath(first, second) {
  return (first.slice(0, second.length) === second && (
    first.length == second.length || first[second.length] === "?"));
};
