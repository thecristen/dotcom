import React from "react";
import ReactDOM from "react-dom";
import SchedulePage from "./components/SchedulePage";
import { SchedulePageData } from "./components/__schedule";

const render = (): void => {
  const schedulePageDataEl = document.getElementById("js-schedule-page-data");
  if (!schedulePageDataEl) return;
  const schedulePageData = JSON.parse(
    schedulePageDataEl.innerHTML
  ) as SchedulePageData;
  ReactDOM.render(
    <SchedulePage schedulePageData={schedulePageData} />,
    document.getElementById("react-root")
  );
};

export const onLoad = (): void => {
  render();
};

export default onLoad;
