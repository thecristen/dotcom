import React from "react";
import ReactDOM from "react-dom";
import StopPageData from "./components/__stop";
import StopPage from "./components/StopPage";

const render = (): void => {
  const dataEl = document.getElementById("js-stop-data");
  if (!dataEl) return;
  const stopPageData = JSON.parse(dataEl.innerHTML) as StopPageData;
  ReactDOM.render(
    <StopPage stopPageData={stopPageData} />,
    document.getElementById("react-root")
  );
};

export const onLoad = (): void => {
  render();
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad as EventListener);
  return true;
};
