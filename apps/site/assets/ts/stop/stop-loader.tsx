import React from "react";
import ReactDOM from "react-dom";
import StopPage from "./components/StopPage";
import { StopPageData, StopMapData } from "./components/__stop";
import { doWhenGoogleMapsIsReady } from "../../js/google-maps-loaded";

const render = (): void => {
  const dataEl = document.getElementById("js-stop-data");
  const mapDataEl = document.getElementById("js-stop-map-data");
  if (!dataEl || !mapDataEl) return;
  const stopPageData = JSON.parse(dataEl.innerHTML) as StopPageData;
  const mapId = dataEl.getAttribute("data-for") as string;
  const mapData = JSON.parse(mapDataEl.innerHTML) as StopMapData;
  ReactDOM.render(
    <StopPage stopPageData={stopPageData} mapId={mapId} mapData={mapData} />,
    document.getElementById("react-root")
  );
};

const renderMap = (): void => {
  doWhenGoogleMapsIsReady(() => {
    render();
  });
};

export const onLoad = (): void => {
  renderMap();
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad as EventListener);
  return true;
};
