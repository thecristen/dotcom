import Sifter from 'sifter';

export function setupSearch() {
  document.addEventListener("turbolinks:load", doSetupSearch, {passive: true});
}

function doSetupSearch() {
  if (document.getElementById("search-bar")) {
    addButtonClasses();

    const searchBar = document.getElementById("search-bar");
    searchBar.addEventListener("keyup", showResults);
    searchBar.addEventListener("blur", hideResults);
  }
}

function buttonList() {
  return Array.from(document.getElementsByClassName("js-search-bar__result"));
}

function addButtonClasses() {
  const cls = [
    "js-search-bar__result",
    "c-search-bar__result",
    "c-search-bar__result--hidden"
  ];
  Array.from(document.getElementById("search-bar__results").children)
    .filter(el => el.href && el.href != "")
    .forEach(btn => btn.classList.add(...cls));
}

function showResults() {
  const data = buttonList().map(el => { return {name: el.getAttribute("data-name")} })
  document.getElementById("search-bar__results").classList
    .remove("c-search-bar__results--hidden");
  Array.from(document.getElementsByClassName("js-search-bar__result"))
    .forEach(btn => btn.classList.add("c-search-bar__result--hidden"));
  const matches = siftStops(data)
  if (matches.length > 0) {
    document.getElementById("search-bar__empty").style.display = "none";
    matches.forEach(addStopToResults);
  } else {
    document.getElementById("search-bar__empty").style.display = "block";
  }
}

function hideResults(ev) {
  if (ev.relatedTarget && ev.relatedTarget.classList.contains("js-search-bar__result")) {
    return;
  } else {
    document.getElementById("search-bar__results").classList.add("c-search-bar__results--hidden");
  }
}

function addStopToResults(stop) {
  const button = Array.from(document.getElementsByClassName("js-search-bar__result"))
                       .find(btn => btn.getAttribute("data-name") == stop.name);
  button.classList.remove("c-search-bar__result--hidden");
}

export function siftStops(data) {
  const sifter = new Sifter(data);
  const value = document.getElementById("search-bar").value
  return sifter.search(value, {
    fields: ['name'],
    sort: [{field: 'name'}],
    limit: 10
  }).items.map(({id: id}) => data[id]);
}
