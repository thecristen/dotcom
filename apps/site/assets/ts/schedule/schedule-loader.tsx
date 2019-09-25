import React from "react";
import ReactDOM from "react-dom";
import SchedulePage from "./components/SchedulePage";
import ScheduleNote from "./components/ScheduleNote";
import ScheduleDirectionAndStops from "./components/ScheduleDirectionAndStops";
import Map from "./components/Map";
import { SchedulePageData } from "./components/__schedule";
import { MapData } from "../leaflet/components/__mapdata";
import ScheduleFinderAccordion from "./components/ScheduleFinderAccordion";
import { SchedulePageDataWithStopListContent } from "./components/ScheduleDirectionAndStops";

const renderMap = (): void => {
  const mapDataEl = document.getElementById("js-map-data");
  if (!mapDataEl) return;
  const channel = mapDataEl.getAttribute("data-channel-id");
  if (!channel) throw new Error("data-channel-id attribute not set");
  const mapEl = document.getElementById("map-root");
  if (!mapEl) throw new Error("cannot find #map-root");
  const mapData: MapData = JSON.parse(mapDataEl.innerHTML);
  ReactDOM.render(<Map data={mapData} channel={channel} />, mapEl);
};

const renderSchedulePage = (schedulePageData: SchedulePageData): void => {
  ReactDOM.render(
    <SchedulePage schedulePageData={schedulePageData} />,
    document.getElementById("react-root")
  );
  if (schedulePageData.schedule_note) {
    ReactDOM.render(
      <ScheduleNote
        className="m-schedule-page__schedule-notes--mobile"
        scheduleNote={schedulePageData.schedule_note}
      />,
      document.getElementById("react-schedule-note-root")
    );
  }
  const {
    direction_id: directionId,
    route,
    stops,
    services,
    route_patterns: routePatternsByDirection
  } = schedulePageData;
  if (route.type !== 0 && route.type !== 1) {
    ReactDOM.render(
      <ScheduleFinderAccordion
        directionId={directionId}
        route={route}
        stops={stops}
        services={services}
        routePatternsByDirection={routePatternsByDirection}
      />,
      document.getElementById("react-schedule-finder-root")
    );
  }
};

const renderDirectionAndStops = (schedulePageData: SchedulePageDataWithStopListContent): void => {
  const root = document.getElementById("react-schedule-direction-and-stops-root");
  if (!root) {
    return;
  }

  ReactDOM.render(
    <ScheduleDirectionAndStops
      {...schedulePageData}
    />,
    root
  );
};

const render = (): void => {
  renderMap();
  const schedulePageDataEl = document.getElementById("js-schedule-page-data");
  if (!schedulePageDataEl) return;
  const schedulePageData = JSON.parse(
    schedulePageDataEl.innerHTML
  ) as SchedulePageDataWithStopListContent;
  renderSchedulePage(schedulePageData);
  renderDirectionAndStops(schedulePageData);
};

export const onLoad = (): void => {
  render();
};

export default onLoad;
