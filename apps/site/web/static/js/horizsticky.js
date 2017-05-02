export default function($) {
  $ = $ || window.jQuery;

  function bindScrollContainers() {
    window.nextTick(
      () =>
        document.querySelectorAll('[data-sticky-container]').forEach(
          (el) => window.setTimeout(initialPosition.bind(el), 0)
        ));
  }

  function initialPosition() {
    var queue = [];
    const stickyElements = this.querySelectorAll("[data-sticky]");
    stickyElements.forEach((el) => {
      const sticky = el.getAttribute('data-sticky');
      const boundingRect = el.getBoundingClientRect();
      const rect = {
        width: Math.ceil(boundingRect.width),
        height: Math.ceil(boundingRect.height)
      };

      if (sticky === "left") {
        queue.push(() => leftSticky(el, rect));
      } else if (sticky === "right") {
        queue.push(() => rightSticky(el, rect));
      }
    });

    // batch all the CSS updates
    window.requestAnimationFrame(() => queue.map((fn) => fn()));
  }

  document.addEventListener('turbolinks:load', bindScrollContainers, {passive: true});
  window.addEventListener('resize', bindScrollContainers, {passive: true});
}

function makeReplacement(child) {
  // we add a replacement element so we can push sibling elements out of
  // the way once we've gone absolute
  var replacement = child.previousElementSibling;
  if (!replacement) {
    replacement = child.cloneNode(true);
    child.parentNode.insertBefore(replacement, child);
    replacement = child;
    replacement.removeAttribute("data-sticky");
  }
  return replacement;
}

function leftSticky(child, rect) {
  const replacement = makeReplacement(child);
  updatePosition(replacement, rect, 'left');
}

function rightSticky(child, rect) {
  const replacement = makeReplacement(child);
  updatePosition(replacement, rect, 'right');
}

function updatePosition(child, rect, position) {
  child.style = `height: ${rect.height}px; width: ${rect.width}px; position: absolute; ${position}: 0;`;
}
