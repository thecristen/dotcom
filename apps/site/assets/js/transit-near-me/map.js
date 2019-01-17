import GoogleMap from "../google-map-class";
import { doWhenGoogleMapsIsReady } from "../google-maps-loaded";

export class TransitNearMeMap {
  constructor(dataEl) {
    const id = dataEl.getAttribute("data-for");
    this.data = JSON.parse(dataEl.innerHTML);
    this.map = new GoogleMap(id, this.data);
    if (this.data.markers.length > 0) {
      this.tightenBounds();
    }
  }

  tightenBounds() {
    this.map.resetBounds(["current-location", "radius-west", "radius-east"]);
  }
}

export default function() {
  const dataEl = document.getElementById("js-tnm-map-dynamic-data");
  if (dataEl) {
    doWhenGoogleMapsIsReady(() => {
      const id = dataEl.getAttribute("data-for");
      const data = JSON.parse(dataEl.innerHTML);
      return new TransitNearMeMap(dataEl);
    });
  }
}
