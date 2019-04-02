import React, { ReactElement } from "react";
import StopMapContainer from "./StopMapContainer";
import { StopPageData, StopMapData } from "./__stop";
import BreadcrumbContainer from "./BreadcrumbContainer";
import Header from "./Header";
import Sidebar from "./Sidebar";
import AddressBlock from "./AddressBlock";
import Departures from "./Departures";
import SuggestedTransfers from "./SuggestedTransfers";

interface Props {
  stopPageData: StopPageData;
  mapData: StopMapData;
  mapId: string;
}

export default ({
  stopPageData: {
    stop,
    routes,
    tabs,
    // eslint-disable-next-line typescript/camelcase
    zone_number: zoneNumber,
    // eslint-disable-next-line typescript/camelcase
    retail_locations: retailLocations,
    // eslint-disable-next-line typescript/camelcase
    suggested_transfers: suggestedTransfers
  },
  mapData,
  mapId
}: Props): ReactElement<HTMLElement> => (
  <>
    <BreadcrumbContainer stop={stop} />
    <Header
      stop={stop}
      routes={routes}
      // eslint-disable-next-line typescript/camelcase
      zoneNumber={zoneNumber}
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
            <SuggestedTransfers suggestedTransfers={suggestedTransfers} />
          </div>
          <div className="col-12 col-sm-10 col-sm-offset-1 col-lg-4 col-lg-offset-1">
            <Sidebar
              stop={stop}
              routes={routes}
              retailLocations={retailLocations}
            />
          </div>
        </div>
      </div>
    </div>
  </>
);
