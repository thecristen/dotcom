import React, { ReactElement } from "react";
import StopMapContainer from "./StopMapContainer";
import { StopPageData, StopMapData } from "./__stop";
import BreadcrumbContainer from "./BreadcrumbContainer";
import Header from "./Header";
import Sidebar from "./Sidebar";
import AddressBlock from "./AddressBlock";

interface Props {
  stopPageData: StopPageData;
  mapData: StopMapData;
  mapId: string;
}

export default ({
  // eslint-disable-next-line typescript/camelcase
  stopPageData: { stop, routes, tabs, zone_number },
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

    <div className="m-stop-page__details">
      <div className="m-stop-page__details-container">Station Details</div>
    </div>
    <div className="m-stop-page__hero">
      <StopMapContainer initialData={mapData} mapId={mapId} stop={stop} />
      <div className="m-stop-page__hero-photo" />
    </div>
    <div className="container">
      <div className="page-section">
        <div className="row">
          <div className="col-lg-7 col-lg-offset-1">
            Main Column
            <AddressBlock routes={routes} />
          </div>
          <div className="col-lg-4">
            <Sidebar stop={stop} routes={routes} />
          </div>
        </div>
      </div>
    </div>
  </>
);
