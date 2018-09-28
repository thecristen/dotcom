import GoogleMap from "./google-map-class";

export class RouteMap {
  constructor(dataEl) {
    const id = dataEl.getAttribute("data-for");
    const data = JSON.parse(dataEl.innerHTML);
    this.map = new GoogleMap(id, data);
  }
}

function init() {
  const maps = document.getElementsByClassName("js-route-map-dynamic-data");

  Array.from(maps).forEach(dataEl => new RouteMap(dataEl));
}

export default function() {
  document.addEventListener("turbolinks:load", init, { passive: true });
}
