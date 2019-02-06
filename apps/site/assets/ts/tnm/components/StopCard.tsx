import React from "react";
import { Stop, Route, SVGMarkers } from "./__tnm";
import { Direction, directionIsEmpty } from "./Direction";

interface Props {
  stop: Stop;
  route: Route;
  markers: SVGMarkers;
}

export const stopIsEmpty = (stop: Stop): boolean =>
  stop.directions.every(directionIsEmpty);

const renderStopMarker = (stop: Stop, markers: SVGMarkers) => {
  const svgText = stop["station?"] ? markers.stationMarker : markers.stopMarker;
  return (
    <span
      className="m-tnm-sidebar__stop-marker"
      dangerouslySetInnerHTML={{ __html: svgText }}
    />
  );
};

export const StopCard = ({ stop, route, markers }: Props) => {
  const key = `${route.id}-${stop.id}`;

  if (stopIsEmpty(stop)) {
    return null;
  }

  return (
    <div className="m-tnm-sidebar__stop">
      <div className="m-tnm-sidebar__stop-info">
        <a href={stop.href} className="m-tnm-sidebar__stop-name">
          {renderStopMarker(stop, markers)} {stop.name}
        </a>
        <div className="m-tnm-sidebar__stop-distance">{stop.distance}</div>
      </div>
      {stop.directions.map(direction => (
        <Direction
          key={direction.direction_id}
          direction={direction}
          route={route}
          stopId={stop.id}
        />
      ))}
    </div>
  );
};

export default StopCard;
