import React from "react";
import { Stop, Route } from "./__tnm";
import { Direction, directionIsEmpty } from "./Direction";

interface Props {
  stop: Stop;
  route: Route;
}

export const stopIsEmpty = (stop: Stop): boolean =>
  stop.directions.every(directionIsEmpty);

export const StopCard = ({ stop, route }: Props) => {
  const key = `${route.id}-${stop.id}`;

  if (stopIsEmpty(stop)) {
    return null;
  }

  return (
    <div className="m-tnm-sidebar__stop">
      <div className="m-tnm-sidebar__stop-info">
        <div className="m-tnm-sidebar__stop-name">{stop.name}</div>
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
