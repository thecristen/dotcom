import React, { ReactElement } from "react";
import Headsign from "./Headsign";
import { Direction, Route } from "../../__v3api";

interface Props {
  direction: Direction;
  route: Route;
  stopId: string;
}

export const directionIsEmpty = (dir: Direction): boolean =>
  dir.headsigns.length === 0;

export const DirectionComponent = ({
  direction,
  route
}: Props): ReactElement<HTMLElement> | null => {
  if (directionIsEmpty(direction)) {
    return null;
  }

  const condensed = direction.headsigns.length === 1;

  const hideDirectionDestination =
    condensed || route.type === 0 || route.type === 1 || route.type === 2;

  return (
    <div>
      <div className="m-tnm-sidebar__direction">
        <div className="m-tnm-sidebar__direction-name u-small-caps">
          {route.direction_names[direction.direction_id]}
        </div>
        {!hideDirectionDestination && (
          <div className="m-tnm-sidebar__direction-destination">
            {route.direction_destinations[direction.direction_id]}
          </div>
        )}
      </div>
      {direction.headsigns.map(headsign => (
        <Headsign
          key={headsign.name}
          headsign={headsign}
          routeType={route.type}
          condensed={condensed}
        />
      ))}
    </div>
  );
};

export default DirectionComponent;
