import { doWhenGoogleMapsIsReady } from "../../js/google-maps-loaded";
import TransitNearMeSearch from "./search";
import render from "./components/map";

let search = null; // eslint-disable-line

const showLoadingIndicators = (bool: boolean): void => {
  const method = bool ? "remove" : "add";
  const loadingIndicators = document.getElementsByClassName(
    "js-loc-loading-indicator"
  );
  Array.from(loadingIndicators).forEach(icon =>
    icon.classList[method]("hidden-xs-up")
  );
};

export const onLocation = ({ coords }: Position): void => {
  showLoadingIndicators(false);
  const { latitude, longitude } = coords;
  const qs = `?latitude=${latitude}&longitude=${longitude}`;
  window.Turbolinks.visit(encodeURI(window.location.protocol + qs));
};

export const onError = (error: PositionError): void => {
  showLoadingIndicators(false);

  if (error.message && error.message.includes("denied")) {
    return;
  }

  const msgEl = document.getElementById("address-search-message");
  if (msgEl) {
    msgEl.innerHTML = `There was an error retrieving your current location;
                       please enter an address to see transit near you.`;
  }
};

const renderMap = (): void => {
  doWhenGoogleMapsIsReady(() => {
    render();
  });
};

const setupSearch = (): void => {
  const el = document.getElementById(TransitNearMeSearch.SELECTORS.container);
  if (el) {
    search = new TransitNearMeSearch();
  }
};

export interface GeolocationData extends CustomEvent {
  data: {
    url: string;
  };
}

export const onLoad = ({ data }: GeolocationData): void => {
  renderMap();
  setupSearch();

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
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad as EventListener);
  return true;
};
