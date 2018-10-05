import GoogleMap from "./google-map-class";

export class RouteMap {
  constructor(dataEl) {
    this.bind();
    this.channelId = dataEl.getAttribute("data-channel");
    const id = dataEl.getAttribute("data-for");
    const data = JSON.parse(dataEl.innerHTML);
    this.map = new GoogleMap(id, data);
    this.addEventListeners();
  }

  bind() {
    this.onVehicles = this.onVehicles.bind(this);
  }

  addEventListeners() {
    window.$(document).on(this.channelId, this.onVehicles);
  }

  onVehicles(ev, { data }) {
    const newHash = {};
    data.forEach(({ marker }) => {
      newHash[marker.id] = true;
    });
    this.map
      .activeMarkers()
      .filter(m => m.id.includes("vehicle-"))
      .forEach(marker => {
        if (!newHash[marker.id]) this.map.removeMarker(marker.id);
      });
    data.forEach(({ marker }) => this.map.addOrUpdateMarker(marker));
  }
}

function init() {
  const maps = document.getElementsByClassName("js-route-map-dynamic-data");
  Array.from(maps).forEach(dataEl => new RouteMap(dataEl));
}

export default function() {
  document.addEventListener("turbolinks:load", init, { passive: true });
}
