export default function addCarets() {
  Array.from(document.getElementsByClassName("js-header-link"))
       .forEach(init);

  function init(el) {
    el.classList.add("navbar-toggle", "toggle-up-down");
    el.setAttribute("data-toggle", "collapse");
    el.setAttribute("aria-expanded", "false");
    const content = Array.from(el.children)
                         .find(child => child.classList.contains("js-header-link__content"));
    addCaret(content);
  }

  function addCaret(el) {
    if (el) {
      const container = document.createElement("div");
      container.classList.add("nav-link-arrows");
      ["up", "down"].map(name => createCaret(name))
                    .forEach(caret => { container.appendChild(caret) });
      el.appendChild(container);
    }
  }

  function createCaret(name) {
    const caret = document.createElement("i");
    caret.classList.add("fa");
    caret.classList.add("fa-angle-" + name);
    caret.classList.add(name);
    caret.setAttribute("aria-hidden", true);
    return caret;
  }
}
