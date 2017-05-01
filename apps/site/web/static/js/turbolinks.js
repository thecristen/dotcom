export default function($) {
  $ = $ || window.jQuery;

  var savedPosition = null;
  var redirectTimeout = null;

  window.addEventListener('popstate', (ev) => {
    var url = window.location.href;

    if (redirectTimeout && !url.match(/redirect/)) {
      window.clearTimeout(redirectTimeout);
      redirectTimeout = null;
    }
  }, {passive: true});

  document.addEventListener('turbolinks:before-visit', (ev) => {
    savedPosition = null;

    // cancel a previously set redirect timeout
    if (redirectTimeout) {
      window.clearTimeout(redirectTimeout);
      redirectTimeout = null;
    }
    const url = ev.data.url;
    const currentPath = `${window.location.protocol}//${window.location.host}${window.location.pathname}`;

    if (samePath(url, currentPath)) {
      savedPosition = [window.scrollX, window.scrollY];
    }
  });

  document.addEventListener('turbolinks:render', (ev) => {
    // if it's cached render, not a real one, set the scroll/focus positions,
    // but don't clear them until we have the true rendering.
    const cachedRender = document.documentElement.getAttribute('data-turbolinks-preview') === '';
    if (!cachedRender && window.location.hash) {
      const el = document.getElementById(window.location.hash.slice(1));
      if (el) {
        scrollToAndFocus(el, $, savedPosition);
      }
    }

    if (savedPosition) {
      window.scrollTo.apply(window, savedPosition);
      if (!cachedRender) {
        savedPosition = null;
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
    redirectTimeout = window.setTimeout(function () {
      document.location = refreshUrl;
    }, refreshDelay);
  }, {passive: true});
};

export function samePath(first, second) {
  return (first.slice(0, second.length) === second && (
    first.length == second.length || first[second.length] === "?"));
};

function scrollToAndFocus(el, $, savedPosition) {
  const nodeName = el.nodeName;
  if (!savedPosition) {
    // scroll to the element if we didn't have another position saved
    window.requestAnimationFrame(() => {
      // wait for the element to render
      const elementY = el.offsetTop;
      window.scroll(window.scrollX, elementY - 20);
    });
  }
  // if we're focusing a link, then focus it directly. otherwise, find
  // the first child link and focus that.
  if (nodeName === "A" || nodeName === "SELECT" || nodeName === "INPUT") {
    el.focus();
  } else {
    const a = el.querySelector('a');
    a.focus();
    scrollToElement(a);
    // if the link we focused is the target for a collapse, then show
    // the collapsed element
    if (a.getAttribute("data-target") == window.location.hash) {
      $(el).collapse('show');
    }
  }
};

function scrollToElement(el, savedPosition) {
  const rect = el.getBoundingClientRect();
  window.scrollBy(0, rect.top);
};
