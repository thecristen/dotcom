import React, { ReactElement } from "react";
import { TNMRoute, TNMStop, RouteGroup, RouteGroupName } from "./__tnm";
import { Dispatch, clickStopCardAction } from "../state";
import ModeIcon from "./ModeIcon";
import { handleReactEnterKeyPress } from "../../helpers/keyboard-events";

export const renderRoutesLabel = (
  routes: TNMRoute[],
  type: RouteGroupName
): ReactElement<HTMLElement> =>
  type === "commuter_rail" ? (
    <a href={routes[0].href}>Commuter Rail</a>
  ) : (
    <span>
      {type === "bus" ? "Bus: " : null}
      {routes.map((r, i: number) => (
        <React.Fragment key={r.id}>
          <a href={r.href}>{r.name}</a>
          {i !== routes.length - 1 ? ", " : ""}
        </React.Fragment>
      ))}
    </span>
  );

export const renderRoutes = (
  routes: TNMRoute[],
  type: RouteGroupName
): ReactElement<HTMLElement> => (
  <div key={type} className="m-tnm-sidebar__stop-card-description">
    <span className="m-tnm-sidebar__stop-route-name">
      <ModeIcon type={type} />
      {renderRoutesLabel(routes, type)}
    </span>
  </div>
);

interface Props {
  stop: TNMStop;
  routes: RouteGroup[];
  dispatch: Dispatch;
}

const StopWithRoutesCard = ({
  stop,
  routes,
  dispatch
}: Props): ReactElement<HTMLElement> => {
  const onClick = (): void => dispatch(clickStopCardAction(stop.id));

  return (
    <div
      className="m-tnm-sidebar__stop-card"
      role="button"
      tabIndex={0}
      onClick={onClick}
      onKeyPress={e => handleReactEnterKeyPress(e, onClick)}
    >
      <div className="m-tnm-sidebar__stop-card-header">
        <a className="m-tnm-sidebar__stop-card-name" href={stop.href}>
          {stop.name}
        </a>
        <div className="m-tnm-sidebar__stop-distance">{stop.distance}</div>
      </div>
      {routes.map(
        ({ group_name: groupName, routes: routesForStop }: RouteGroup) =>
          renderRoutes(routesForStop, groupName)
      )}
    </div>
  );
};

export default StopWithRoutesCard;
