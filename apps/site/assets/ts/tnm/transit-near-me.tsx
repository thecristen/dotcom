import React from "react";
import ReactDOM from "react-dom";
import { MapData } from "./components/__tnm";
import { doWhenGoogleMapsIsReady } from "../../js/google-maps-loaded";
import TransitNearMeSearch from "./search";
import TransitNearMe from "./components/TransitNearMe";

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

const getSidebarOffset = (): number => {
  const containerEl = document
    .getElementsByClassName("container")
    .item(0) as HTMLElement;

  if (containerEl) {
    return containerEl.offsetLeft;
  }

  return 0;
};

const render = (): void => {
  const dataEl = document.getElementById("js-tnm-map-dynamic-data");
  const sidebarDataEl = document.getElementById("js-tnm-sidebar-data");
  if (!dataEl || !sidebarDataEl) return;
  const mapId = dataEl.getAttribute("data-for") as string;
  const mapData = JSON.parse(dataEl.innerHTML) as MapData;
  const sidebarData = JSON.parse(sidebarDataEl.innerHTML);
  ReactDOM.render(
    <TransitNearMe
      mapData={mapData}
      mapId={mapId}
      sidebarData={sidebarData}
      getSidebarOffset={getSidebarOffset}
    />,
    document.getElementById("react-root")
  );
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

export const onLoad = (): void => {
  renderMap();
  setupSearch();
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad as EventListener);
  return true;
};
