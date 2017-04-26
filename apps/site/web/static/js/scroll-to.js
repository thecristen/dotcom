export default function($) {
  $ = $ || window.jQuery;

  function scrollTo() {
    $("[data-scroll-to]").each((index, el) => window.setTimeout(doScrollTo.bind(el), 0));
  }

  function handleScroll(ev) {
    const scrollPos = ev.target.scrollLeft;
    const containerWidth = ev.target.clientWidth;
    const table = firstElementChild(ev.target);
    const rect = table.getBoundingClientRect();

    const hideEarlier = scrollPos < 48;
    const hideLater = rect.width - containerWidth - scrollPos < 48;

    requestAnimationFrame(function() {
      if (scrollPos < 0) {
        ev.target.scrollLeft = 0;
      }

      toggleClass(table, 'schedule-v2-timetable-hide-earlier', hideEarlier);
      toggleClass(table, 'schedule-v2-timetable-hide-later', hideLater);
    });
  }

  function doScrollTo() {
    const childLeft = this.offsetLeft;
    const parentLeft = this.parentNode.offsetLeft;
    const firstSiblingWidth = firstSibling(this).getBoundingClientRect().width;

    // childLeft - parentLeft scrolls the first row to the start of the
    // visible area.
    const scrollLeft = childLeft - parentLeft - firstSiblingWidth;
    var table = this.parentNode;
    while (table.nodeName !== "TABLE") {
      table = table.parentNode;
    }
    table.parentNode.addEventListener('scroll', handleScroll);
    table.parentNode.scrollLeft = scrollLeft;
    if (table.className.indexOf("vertically-centered") === -1) {
      requestAnimationFrame(() => verticallyCenter($, table, table.getBoundingClientRect().height, 'schedule-v2-timetable-more-text'));
    }
  }

  document.addEventListener('turbolinks:load', scrollTo);
}

function firstSibling(element) {
  var previous = element.previousElementSibling;
  while (element) {
    if (!previous) {
      return element;
    }
    element = previous;
    previous = element.previousElementSibling;
  }
  return null;
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

function verticallyCenter($, el, height, className) {
  const styles = getComputedStyle(el.parentNode);
  const bottomBorder = parseInt(styles.borderBottomWidth);
  var sized = false;
  var elements;

  if (el.getElementsByClassName) {
    elements = el.getElementsByClassName(className);
  } else {
    elements = $(el).find(".${className}");
  }
  $.each(elements, function(index, textEl) {
    // vertically center the timetable text if visible
    const box = textEl.getBoundingClientRect();
    if (box.width) {
      const top = Math.floor((height - box.height + bottomBorder) / 2);
      textEl.style.top = `${top}px`;
      sized = true;
    }
  });

  if (sized) {
    el.className += 'vertically-centered';
  }
}
