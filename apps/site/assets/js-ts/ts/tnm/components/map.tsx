// @ts-ignore: Not typed
import GoogleMap from "../../../js/google-map-class";

class TransitNearMeMap {
  /* eslint-disable typescript/no-explicit-any */
  public data: any;

  public map: any;
  /* eslint-enable typescript/no-explicit-any */

  constructor(dataEl: HTMLElement) {
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

const render = (): void => {
  const dataEl = document.getElementById("js-tnm-map-dynamic-data");
  if (dataEl) {
    new TransitNearMeMap(dataEl);
  }
};

export default render;
