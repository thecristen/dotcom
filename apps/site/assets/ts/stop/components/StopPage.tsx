import React, { ReactElement, useReducer } from "react";
import StopMapContainer from "./StopMapContainer";
import { StopPageData, StopMapData } from "./__stop";
import { reducer, initialState } from "../state";
import StopPageHeader from "./StopPageHeader";
import Alerts from "../../components/Alerts";
import AlertsTab from "./AlertsTab";
import Sidebar from "./Sidebar";
import AddressBlock from "./AddressBlock";
import Departures from "./Departures";
import SuggestedTransfers from "./SuggestedTransfers";

interface Props {
  stopPageData: StopPageData;
  mapData: StopMapData;
  mapId: string;
  encoder?: (component: string) => string;
}

export default ({
  stopPageData,
  mapData,
  mapId,
  encoder
}: Props): ReactElement<HTMLElement> => {
  const {
    stop,
    street_view_url: streetViewUrl,
    routes,
    // eslint-disable-next-line typescript/camelcase
    retail_locations: retailLocations,
    // eslint-disable-next-line typescript/camelcase
    suggested_transfers: suggestedTransfers,
    alerts,
    alerts_tab: alertsTab,
    tab
  } = stopPageData;

  const [state, dispatch] = useReducer(reducer, initialState(tab));

  const highPriorityAlerts = alerts.filter(alert => alert.priority === "high");

  return (
    <>
      <StopPageHeader
        stopPageData={stopPageData}
        dispatch={dispatch}
        selectedTab={state.selectedTab}
      />
      {state.selectedTab === "alerts" ? (
        <AlertsTab alertsTab={alertsTab} />
      ) : (
        <>
          <Alerts alerts={highPriorityAlerts} />
          <div className="container">
            <h2>Station Information</h2>
            <p>
              See upcoming departures, maps, and other features at this
              location.
            </p>
          </div>
          <div className="m-stop-page__hero">
            <StopMapContainer
              initialData={mapData}
              mapId={mapId}
              stop={stop}
              selectedStopId={state.selectedStopId}
              dispatch={dispatch}
            />
            <div className="m-stop-page__hero-photo" />
          </div>
          <div className="container">
            <div className="page-section">
              <div className="row">
                <div className="col-12 col-sm-10 col-sm-offset-1 col-lg-7 col-lg-offset-0">
                  <AddressBlock
                    stop={stop}
                    routes={routes}
                    encoder={encoder}
                    streetViewUrl={streetViewUrl}
                  />
                  <Departures
                    routes={routes}
                    stop={stop}
                    selectedModes={state.selectedModes}
                    dispatch={dispatch}
                  />
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
      )}
    </>
  );
};
