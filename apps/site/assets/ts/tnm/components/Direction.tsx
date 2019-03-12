import React, { ReactElement } from "react";
import Headsign from "./Headsign";
import { TNMDirection, TNMRoute } from "./__tnm";

interface Props {
  direction: TNMDirection;
  route: TNMRoute;
  stopId: string;
}

export const directionIsEmpty = (dir: TNMDirection): boolean =>
  dir.headsigns.length === 0;

export const Direction = ({
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

export default Direction;
