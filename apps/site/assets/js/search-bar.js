import Sifter from 'sifter';

export function setupSearch() {
  const searchBar = document.getElementById("search-bar");
  const buttons = document.getElementById("search-bar__results").children;
  Array.from(buttons).forEach(btn => btn.classList.add("js-search-bar__result", "c-search-bar__result"));
  const data = Array.from(buttons).map(el => { return {name: el.getAttribute("data-name")} })

  searchBar.addEventListener("keyup", showResults(data));
}

function showResults(data) {
  return (ev) => {
    document.getElementById("search-bar__results").classList
      .remove("c-search-bar__results--hidden");
    Array.from(document.getElementsByClassName("js-search-bar__result"))
      .forEach(btn => btn.classList.add("c-search-bar__result--hidden"));
    siftStops(data).forEach(addStopToResults);
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
    sort: [{field: 'name', direction: 'asc'}],
    limit: 10
  }).items.map(({id: id}) => data[id]);
}
