import React from "react";
import Headsign from "./Headsign";
import { Route, TNMDirection } from "./__tnm";

interface Props {
  direction: TNMDirection;
  route: Route;
  stopId: string;
}

export const directionIsEmpty = (dir: TNMDirection): boolean =>
  dir.headsigns.length === 0;

export const Direction = ({ direction, route, stopId }: Props) => {
  if (directionIsEmpty(direction)) {
    return null;
  }

  return (
    <div>
      <div className="m-tnm-sidebar__direction">
        <div className="m-tnm-sidebar__direction-name u-small-caps">
          {route.direction_names[direction.direction_id]}
        </div>
        <div className="m-tnm-sidebar__direction-destination">
          {route.direction_destinations[direction.direction_id]}
        </div>
      </div>
      {direction.headsigns.map(headsign => (
        <Headsign key={headsign.name} headsign={headsign} />
      ))}
    </div>
  );
};

export default Direction;
