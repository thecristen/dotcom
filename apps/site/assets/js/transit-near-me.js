import GoogleMap from "./google-map-class";
import { doWhenGoogleMapsIsReady } from "./google-maps-loaded";

let map;

const showLoadingIndicators = bool => {
  const method = bool ? "remove" : "add";
  const loadingIndicators = document.getElementsByClassName(
    "js-loc-loading-indicator"
  );
  return Array.from(loadingIndicators).forEach(icon =>
    icon.classList[method]("hidden-xs-up")
  );
};

export const onLocation = loc => {
  showLoadingIndicators(false);
  const { latitude, longitude } = loc.coords;
  const qs = `?latitude=${latitude}&longitude=${longitude}`;
  return window.Turbolinks.visit(encodeURI(window.location.protocol + qs));
};

export const onError = error => {
  showLoadingIndicators(false);

  if (error.message && error.message.includes("denied")) {
    return false;
  }

  const msgEl = document.getElementById("address-search-message");
  if (msgEl) {
    msgEl.innerHTML = `There was an error retrieving your current location;
                       please enter an address to see transit near you.`;
  }
};

const loadMap = () => {
  const dataEl = document.getElementById("js-tnm-map-dynamic-data");
  if (dataEl) {
    doWhenGoogleMapsIsReady(() => {
      const id = dataEl.getAttribute("data-for");
      const data = JSON.parse(dataEl.innerHTML);
      map = new GoogleMap(id, data);
    });
  }
};

export const onLoad = ({ data }) => {
  loadMap();

  if (data && data.url) {
    const url = window.decodeURIComponent(data.url);

    if (
      window.navigator &&
      window.navigator.geolocation &&
      url.includes("/transit-near-me") &&
      url.includes("address") === false &&
      url.includes("latitude") === false &&
      url.includes("longitude") === false
    ) {
      showLoadingIndicators(true);
      window.navigator.geolocation.getCurrentPosition(onLocation, onError);
    }
  }
  return true;
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad);
  return true;
};
