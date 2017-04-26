export default function($) {
  $ = $ || window.jQuery;

  function bindScrollContainers() {
    document.querySelectorAll('[data-sticky-container]').forEach(
      (el) => window.setTimeout(initialPosition.bind(el), 0)
    );
  }

  function initialPosition() {
    var queue = [];
    const stickyElements = this.querySelectorAll("[data-sticky]");
    stickyElements.forEach(makeReplacement);
    stickyElements.forEach((el) => {
        el.style = 'width: auto; height: auto; position: relative;';
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

  document.addEventListener('turbolinks:load', bindScrollContainers);
  window.addEventListener('resize', bindScrollContainers);
}

function makeReplacement(child) {
  // we add a replacement element so we can push sibling elements out of
  // the way once we've gone absolute
  var replacement = previousElement(child);
  if (!replacement) {
    replacement = document.createElement(child.tagName);
    replacement.className = 'sticky-replacement';
    replacement.innerText = ' ';
    child.parentNode.insertBefore(replacement, child);
  }
  return replacement;
}

function leftSticky(child, rect) {
  makeReplacement(child).style = `padding-left: ${rect.width}px; height: ${rect.height}px;`;

  // update our CSS position/size
  updatePosition(child, rect, 'left');
}

function rightSticky(child, rect) {
  makeReplacement(child).style = `padding-right: ${rect.width}px; height: ${rect.height}px;`;

  updatePosition(child, rect, 'right');
}

function previousElement(el) {
  var previous = el.previousSibling;
  while (el.nodeType !== 1) {
    previous = previous.previousSibling;
  }
}

function updatePosition(child, rect, position) {
  child.style = `height: ${rect.height}px; width: ${rect.width}px; position: absolute; ${position}: 0;`;
}
