import React, { ReactElement } from "react";
import { SuggestedTransfer } from "./__stop";
import { modeIcon } from "../../helpers/icon";
import accessible from "./StopAccessibilityIcon";
import { Route, DirectionId } from "../../__v3api";

const fomatMilesToFeet = (miles: number): number => Math.floor(miles * 5280.0);

interface Props {
  suggestedTransfers: SuggestedTransfer[];
}

interface TransferProps {
  suggestedTransfer: SuggestedTransfer;
}

const routeNameBasedOnDirection = (
  route: Route,
  directionId: DirectionId | null
): string =>
  directionId === null
    ? route.long_name
    : // eslint-disable-next-line typescript/camelcase
      route.direction_destinations[directionId];

const Transfer = ({
  suggestedTransfer: {
    stop,
    distance,
    routes_with_direction: routesWithDirection
  }
}: TransferProps): ReactElement<HTMLElement> => (
  <div className="m-stop-page__transfer">
    <span className="m-stop-page__transfer-distance">
      {fomatMilesToFeet(distance)} ft
    </span>
    <a
      className="m-stop-page__transfer-stop-name"
      href={`/stops-v2/${stop.id}`}
    >
      {stop.name}
    </a>
    {accessible(stop)}
    {routesWithDirection.map(({ route, direction_id: directionId }) => (
      <div
        className="m-stop-page__transfer-route"
        key={`suggestedTransferRoute${route.id}`}
      >
        {route.type === 3 && !route.name.startsWith("SL") ? (
          <div className="m-stop-page__transfer-bus-pill u-bg--bus u-small-class">
            {route.id}
          </div>
        ) : (
          modeIcon(route.id)
        )}
        <a
          href={`/schedules/${route.id}${
            directionId !== null ? `?direction_id=${directionId}` : ""
          }`}
          className="m-stop-page__transfer-route-link"
        >
          {routeNameBasedOnDirection(route, directionId)}
        </a>
      </div>
    ))}
  </div>
);

export default ({
  suggestedTransfers
}: Props): ReactElement<HTMLElement> | null =>
  suggestedTransfers.length === 0 ? null : (
    <div>
      <h2>Suggested Transfers Nearby</h2>
      <div className="m-stop-page__transfers">
        {suggestedTransfers.map((suggestedTransfer: SuggestedTransfer) => (
          <Transfer
            key={`transfer${suggestedTransfer.stop.id}`}
            suggestedTransfer={suggestedTransfer}
          />
        ))}
      </div>
    </div>
  );
