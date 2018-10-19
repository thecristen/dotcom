import sinon from "sinon";

class Map {
  constructor() {
    this.zoom = 0;
    this.center = new LatLng(0, 0);
    this.setZoom = this.setZoom.bind(this);
    this.setCenter = this.setCenter.bind(this);
    this.setOptions = sinon.spy();
  }

  setZoom(zoom) {
    this.zoom = zoom;
  }

  getZoom() {
    return this.zoom;
  }

  setCenter(latLng) {
    this.center = latLng;
  }
}

class LatLng {
  constructor(lat, lng) {
    this.lat = lat;
    this.lng = lng;
  }

  equals(latLng) {
    return (this.lat === latLng.lat) && (this.lng === latLng.lng);
  }
}

class LatLngBounds {
  constructor() {
    this.ne = new LatLng(0, 0);
    this.sw = new LatLng(0, 0);
  }

  getNorthEast() {
    return this.ne;
  }

  getSouthWest() {
    return this.sw;
  }
}

class Marker {
  constructor(opts) {
    this.position = opts.position;
    this.map = opts.map;
  }

  setPosition(latLng) {
    this.position = latLng;
  }

  getPosition() {
    return this.position;
  }

  setIcon() {
    return this;
  }
}

export default {
  maps: {
    Map: Map,
    LatLng: LatLng,
    LatLngBounds: LatLngBounds,
    Marker: Marker,
    event: {
      addListenerOnce: sinon.spy()
    }
  }
};
