import Sifter from 'sifter';

export const STYLE_CLASSES = {
  RESULT_LIST: {
    ELEMENT: "c-search-bar__results",
    HIDDEN: "c-search-bar__results--hidden"
  },
  RESULT: {
    ELEMENT: "c-search-bar__result",
  }
}

export const SELECTORS = {
  CLASSES: {
    RESULT: "js-search-bar__result"
  },
  IDS: {
    INPUT: "search-bar",
    RESULT_LIST: "search-bar__results",
    EMPTY_MSG: "search-bar__empty"
  }
}

export function setupSearch() {
  document.addEventListener("turbolinks:load", doSetupSearch, {passive: true});
  document.addEventListener("turbolinks:before-cache", hideResults, {passive: true});
}

function doSetupSearch() {
  const searchBar = document.getElementById(SELECTORS.IDS.INPUT);
  if (searchBar) {
    addButtonClasses();

    searchBar.addEventListener("keyup", showResults);
  }
}

export function buttonList() {
  return Array.from(document.getElementsByClassName(SELECTORS.CLASSES.RESULT));
}

export function addButtonClasses() {
  const cls = [
    SELECTORS.CLASSES.RESULT,
    STYLE_CLASSES.RESULT.ELEMENT
  ];
  Array.from(document.getElementById(SELECTORS.IDS.RESULT_LIST).children)
    .filter(el => el.href && el.href != "")
    .forEach(btn => btn.classList.add(...cls));
}

export function showResults() {
  document.addEventListener("click", hideResults);
  const data = buttonList().map(el => { return {name: el.getAttribute("data-name")} })
  document.getElementById(SELECTORS.IDS.RESULT_LIST).classList
    .remove(STYLE_CLASSES.RESULT_LIST.HIDDEN);
  buttonList().forEach(hideButton);
  const matches = siftStops(data, document.getElementById(SELECTORS.IDS.INPUT).value)
  if (matches.length > 0) {
    document.getElementById(SELECTORS.IDS.EMPTY_MSG).style.display = "none";
    matches.forEach(addStopToResults);
  } else {
    document.getElementById(SELECTORS.IDS.EMPTY_MSG).style.display = "block";
  }
}

function hideButton(btn) {
  btn.style.display = "none"
}

function hideResults() {
  document.removeEventListener("click", hideResults);
  const input = document.getElementById(SELECTORS.IDS.INPUT);
  if (input) {
    document.getElementById(SELECTORS.IDS.INPUT).value = "";
    document.getElementById(SELECTORS.IDS.RESULT_LIST).classList.add(STYLE_CLASSES.RESULT_LIST.HIDDEN);
  }
}

function addStopToResults(stop) {
  buttonList().find(btn => btn.getAttribute("data-name") == stop.name)
    .style.display = "flex";
}

export function siftStops(data, value) {
  const sifter = new Sifter(data);
  return sifter.search(value, {
    fields: ['name'],
    sort: [{field: 'name'}],
    limit: 10
  }).items.map(({id: id}) => data[id]);
}
