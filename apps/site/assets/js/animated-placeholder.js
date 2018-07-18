const defaultTimeout = 3000;
export const placeholderId = "animated-input-placeholder";
export const paused = {};

export const updateIndex = (idx, placeholdersLength) => {
  const nextIdx = idx + 1;
  if (nextIdx === placeholdersLength) {
    return 0;
  }
  return nextIdx;
};

export const addPlaceholder = inputId => {
  if (document.getElementById(placeholderId)) {
    return false;
  }

  const el = document.createElement("div");
  el.classList.add("c-form__animated-placeholder");
  el.id = placeholderId;
  document.getElementById(inputId).parentNode.appendChild(el);
  return true;
};

const onFocusOrKeyup = ev => {
  const isPaused = ev.target.value !== "";
  paused[ev.target.id] = isPaused;
  if (isPaused) {
    const placeholder = document.getElementById(placeholderId);
    if (placeholder) placeholder.style.display = "none";
  }
};

export const run = (id, placeholders, idx, timeout) => {
  const input = document.getElementById(id);

  if (input && input.value === "" && paused[id] === false) {
    const $placeholder = window.$(`#${placeholderId}`);
    const nextIdx = updateIndex(idx, placeholders.length);

    return $placeholder
      .html(placeholders[idx])
      .fadeIn()
      .delay(timeout)
      .fadeOut(1000, () => run(id, placeholders, nextIdx, timeout));
  }

  return window.requestAnimationFrame(() => run(id, placeholders, idx, timeout));
};

export const teardown = () => {
  Object.keys(paused).forEach(key => {
    paused[key] = false;
  });
  window.$(`#${placeholderId}`).remove();
};

export const animatePlaceholder = (
  id,
  placeholders,
  timeout = defaultTimeout
) => {
  paused[id] = false;
  const el = document.getElementById(id);

  if (el) {
    el.classList.add("c-form__input--with-animated-placeholder");
    el.addEventListener("focus", onFocusOrKeyup);
    el.addEventListener("keyup", onFocusOrKeyup);

    addPlaceholder(id);
    document.addEventListener("turbolinks:before-cache", teardown);
    return run(id, placeholders, 0, timeout);
  }

  return false;
};
