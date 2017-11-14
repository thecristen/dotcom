export default function($) {
  $ = $ || window.jQuery;

  function scrollTo() {
    window.requestAnimationFrame(
      () => {
        const elements = document.querySelectorAll("[data-scroll-to]");
        Array.prototype.forEach.call(
          elements,
          doScrollTo);
      });
  }

  function handleScroll(ev) {
    const scrollPos = ev.target.scrollLeft;
    const containerWidth = ev.target.clientWidth;
    const table = firstElementChild(ev.target);
    const width = table.clientWidth;

    const hideEarlier = scrollPos < 48;
    const hideLater = width - containerWidth - scrollPos < 48;

    requestAnimationFrame(function() {
      if (scrollPos < 0) {
        ev.target.scrollLeft = 0;
      }

      toggleClass(table, 'schedule-v2-timetable-hide-earlier', hideEarlier);
      toggleClass(table, 'schedule-v2-timetable-hide-later', hideLater);
    });
  }

  function doScrollTo(el) {
    const childLeft = el.offsetLeft;
    const parentLeft = el.parentNode.offsetLeft;
    const firstSiblingWidth = firstSibling(el).clientWidth;

    // childLeft - parentLeft scrolls the first row to the start of the
    // visible area.
    const scrollLeft = childLeft - parentLeft - firstSiblingWidth;
    var table = el.parentNode;
    while (table.nodeName !== "TABLE") {
      table = table.parentNode;
    }
    table.parentNode.addEventListener('scroll', handleScroll);
    table.parentNode.scrollLeft = scrollLeft;
    if (table.className.indexOf("vertically-centered") === -1) {
      const tableHeight = table.clientHeight;
      window.requestAnimationFrame(
        () => verticallyCenter($, table, tableHeight, 'schedule-v2-timetable-more-text'));
    }
  }

  document.addEventListener('turbolinks:load', scrollTo, {passive: true});
}

function firstSibling(element) {
  const sibling = element.parentNode.firstChild;
  if (sibling.nodeType === 1) {
    return sibling;
  } else if (sibling) {
    return sibling.nextElementSibling;
  } else {
    return null;
  }
}

function toggleClass(element, newClass, bool) {
  const className = element.className;
  const hasClass = className.indexOf(newClass) !== -1;

  if (hasClass && !bool) {
    // remove class
    element.className = className.replace(newClass, "");
  }
  if (!hasClass && bool) {
    // add class
    element.className += ` ${newClass}`;
  }
}

function firstElementChild(element) {
  var child = element.firstChild;
  while (child.nodeType !== 1) {
    child = child.nextSibling;
  }
  return child;
}

function verticallyCenter($, el, tableHeight, className) {
  const styles = window.getComputedStyle(el.parentNode),
        halfTableHeight = tableHeight / 2;
  var sized = false;
  var elements;

  if (el.getElementsByClassName) {
    elements = el.getElementsByClassName(className);
  } else {
    elements = $(el).find(`.${className}`);
  }
  Array.prototype.forEach.call(elements, (textEl) => {
    // vertically center the timetable text if visible
    const height = textEl.offsetHeight;

    if (height) {
      const top = Math.floor(halfTableHeight - (height / 2));
      window.requestAnimationFrame(() => textEl.style.top = `${top}px`);
      sized = true;
    }
  });

  if (sized) {
    el.className += 'vertically-centered';
  }
}
