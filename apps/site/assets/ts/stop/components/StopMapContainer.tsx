import React, { ReactElement, useReducer } from "react";
import StopMap from "./StopMap";
import { reducer, initialState } from "../state";
import { StopMapData } from "../components/__stop";
import { Stop } from "../../__v3api";

interface Props {
  initialData: StopMapData;
  mapId: string;
  stop: Stop;
}

const StopMapContainer = (props: Props): ReactElement<HTMLElement> => {
  const { initialData, mapId, stop } = props;
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <div className="m-stop-page__hero-map">
      <div id={mapId} className="m-stop-page__hero-map-container" />
      <noscript>
        <style>{`#${mapId} { display: none; }`}</style>
        <div className="m-stop-page__hero-map-container">
          <a
            href={`https://maps.google.com/?q=${stop.address}`}
            rel="noopener noreferrer"
            target="_blank"
          >
            {/* This generates a srcset for our responsive image component,
    based on the sizes of the current iframe.  It generates a
    srcset entry for each width/height pair, as well as a
            double-width entry for the 2x scaled Google Maps image. */}
            <img
              className="map-static map-static-img"
              alt={`Map of ${stop.name} and surrounding area`}
              srcSet={initialData.map_srcset}
              sizes="(min-width: 1344px) 1099w,
        (min-width: 1088px) 734w,
        (min-width: 800px) 694w,
        calc(100vw - 1.5rem)"
              src={initialData.map_url}
            />
          </a>
        </div>
      </noscript>

      <StopMap
        mapElementId={mapId}
        dispatch={dispatch}
        selectedStopId={state.selectedStopId}
        initialData={initialData}
      />
    </div>
  );
};

export default StopMapContainer;
