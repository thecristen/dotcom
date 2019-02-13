import React from "react";
import TransitNearMeMap from "./TransitNearMeMap";
import RoutesSidebar from "./RoutesSidebar";
import { Route } from "./__tnm";

interface Props {
  mapData: any;
  mapId: string;
  sidebarData: Route[];
  getSidebarOffset: () => number;
}

const TransitNearMe = ({
  mapData,
  mapId,
  sidebarData,
  getSidebarOffset
}: Props) => {
  return (
    <div className="m-tnm">
      <div id={mapId} className="m-tnm__map" />
      <TransitNearMeMap mapElementId={mapId} initialData={mapData} />
      <RoutesSidebar data={sidebarData} getOffset={getSidebarOffset} />
    </div>
  );
};

export default TransitNearMe;
