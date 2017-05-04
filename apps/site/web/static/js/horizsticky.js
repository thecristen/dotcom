export default function($) {
  $ = $ || window.jQuery;

  function bindScrollContainers() {
    window.requestAnimationFrame(() => {
      const containerElements = document.querySelectorAll('[data-sticky-container]');
      Array.prototype.forEach.call(
        containerElements,
        initialPosition);
    });
  }

  function initialPosition(container) {
    var queue = [];
    const stickyElements = container.querySelectorAll("[data-sticky]");
    Array.prototype.forEach.call(stickyElements, (el) => {
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
    window.requestAnimationFrame(() => {
      queue.map((fn) => fn());
    });

  }

  document.addEventListener('turbolinks:load', bindScrollContainers, {passive: true});
  window.addEventListener('resize', bindScrollContainers, {passive: true});
}

function makeReplacement(child) {
  // we add a replacement element so we can push sibling elements out of
  // the way once we've gone absolute
  var replacement = child.nextElementSibling;
  if (!replacement || replacement.className !== child.className) {
    replacement = child.cloneNode(true);
    child.parentNode.insertBefore(replacement, child.nextSibling);
    replacement.removeAttribute("data-sticky");
  }
  return replacement;
}

function leftSticky(child, rect) {
  const replacement = makeReplacement(child);
  updatePosition(replacement, rect, 'left');
  child.style.height = `${rect.height}px`;
}

function rightSticky(child, rect) {
  const replacement = makeReplacement(child);
  updatePosition(replacement, rect, 'right');
  child.style.height = `${rect.height}px`;
}

function updatePosition(child, rect, position) {
  child.style.cssText = `height: ${rect.height}px; width: ${rect.width}px; position: absolute; ${position}: 0;`;
}
