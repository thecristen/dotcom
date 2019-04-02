import React, { ReactElement } from "react";
import StopMapContainer from "./StopMapContainer";
import { StopPageData, StopMapData } from "./__stop";
import BreadcrumbContainer from "./BreadcrumbContainer";
import Header from "./Header";
import Sidebar from "./Sidebar";
import AddressBlock from "./AddressBlock";
import Departures from "./Departures";

interface Props {
  stopPageData: StopPageData;
  mapData: StopMapData;
  mapId: string;
}

export default ({
  // eslint-disable-next-line typescript/camelcase
  stopPageData: { stop, routes, tabs, zone_number, retail_locations },
  mapData,
  mapId
}: Props): ReactElement<HTMLElement> => (
  <>
    <BreadcrumbContainer stop={stop} />
    <Header
      stop={stop}
      routes={routes}
      // eslint-disable-next-line typescript/camelcase
      zoneNumber={zone_number}
      tabs={tabs}
    />
    <div className="container">
      <h2>Station Information</h2>
      <p>See upcoming departures, maps, and other features at this location.</p>
    </div>
    <div className="m-stop-page__hero">
      <StopMapContainer initialData={mapData} mapId={mapId} stop={stop} />
      <div className="m-stop-page__hero-photo" />
    </div>
    <div className="container">
      <div className="page-section">
        <div className="row">
          <div className="col-12 col-sm-10 col-sm-offset-1 col-lg-7 col-lg-offset-0">
            <AddressBlock routes={routes} />

            <Departures routes={routes} stop={stop} />
          </div>
          <div className="col-12 col-sm-10 col-sm-offset-1 col-lg-4 col-lg-offset-1">
            <Sidebar
              stop={stop}
              routes={routes}
              // eslint-disable-next-line typescript/camelcase
              retailLocations={retail_locations}
            />
          </div>
        </div>
      </div>
    </div>
  </>
);
