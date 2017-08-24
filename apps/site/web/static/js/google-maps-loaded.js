let callbacks = [];

export default function () {
  window.mapsCallback = function() {
    window.isMapReady = true;
    let callback;
    while (callbacks.length > 0) {
      callback = callbacks.shift();
      callback();
    }
  }
}

export function doWhenGooleMapsIsReady (callback) {
  window.isMapReady ? callback() : callbacks.push(callback);
}
