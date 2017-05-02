export default function($, w = window, doc = document) {
  $ = $ || w.jQuery;

  var savedPosition = null;
  var redirectTimeout = null;
  var lastUrl = currentUrl();

  w.addEventListener('popstate', (ev) => {
    var url = w.location.href;

    if (redirectTimeout && !url.match(/redirect/)) {
      w.clearTimeout(redirectTimeout);
      redirectTimeout = null;
    }

    lastUrl = currentUrl();
  }, {passive: true});

  doc.addEventListener('turbolinks:before-visit', (ev) => {
    savedPosition = null;

    // cancel a previously set redirect timeout
    if (redirectTimeout) {
      w.clearTimeout(redirectTimeout);
      redirectTimeout = null;
    }
    const url = ev.data.url;

    if (samePath(url, lastUrl)) {
      savedPosition = [w.scrollX, w.scrollY];
    }

    lastUrl = currentUrl();
  }, {passive: true});

  doc.addEventListener('turbolinks:render', () => {
    // if it's cached render, not a real one, set the scroll/focus positions,
    // but don't clear them until we have the true rendering.
    const cachedRender = doc.documentElement.getAttribute('data-turbolinks-preview') === '';
    if (!cachedRender && w.location.hash) {
      const el = doc.getElementById(w.location.hash.slice(1));
      if (el) {
        savedPosition = null;
        focusAndExpand(el, $);
      }
    }

    if (savedPosition) {
      w.scrollTo.apply(window, savedPosition);
      if (!cachedRender) {
        savedPosition = null;
      }
    }
  }, {passive: true});

  doc.addEventListener('turbolinks:request-end', (ev) => {
    // if a refresh header was receieved, enforce via javascript
    var refreshHeader = ev.data.xhr.getResponseHeader("Refresh");
    if (!refreshHeader) {
      return;
    }

    // parse data from the header
    var refreshUrl = refreshHeader.substring(refreshHeader.indexOf('=') + 1);
    var refreshDelay = refreshHeader.split(';')[0] * 1000;

    // redirect after 5 seconds
    redirectTimeout = w.setTimeout(function () {
      doc.location = refreshUrl;
    }, refreshDelay);
  }, {passive: true});
};

export function samePath(first, second) {
  return (first.slice(0, second.length) === second && (
    first.length == second.length || first[second.length] === "?"));
};

function currentUrl() {
  return `${window.location.protocol}//${window.location.host}${window.location.pathname}`;
}

function focusAndExpand(el, $) {
  const nodeName = el.nodeName;
  // if we're focusing a link, then focus it directly. otherwise, find
  // the first child link and focus that.
  if (nodeName === "A" || nodeName === "SELECT" || nodeName === "INPUT") {
    el.focus();
    scrollToElement(el);
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
  window.requestAnimationFrame(() => {
    const rect = el.getBoundingClientRect();
    window.scrollBy(0, rect.top);
  });
};
