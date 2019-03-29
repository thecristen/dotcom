import React, { ReactElement } from "react";
import { Mode, Route, Stop } from "../../__v3api";
import { RouteGroup } from "./__tnm";
import { Dispatch, clickStopCardAction } from "../state";
import ModeIcon from "./ModeIcon";
import { handleReactEnterKeyPress } from "../../helpers/keyboard-events";

export const renderRoutesLabel = (
  routes: Route[],
  type: Mode
): ReactElement<HTMLElement> =>
  type === "commuter_rail" ? (
    <a href={routes[0].href}>Commuter Rail</a>
  ) : (
    <span>
      {type === "bus" ? "Bus: " : null}
      {routes.map((route, i: number) => (
        <React.Fragment key={route.id}>
          <a href={route.href}>{route.name}</a>
          {i !== routes.length - 1 ? ", " : ""}
        </React.Fragment>
      ))}
    </span>
  );

export const renderRoutes = (
  routes: Route[],
  type: Mode
): ReactElement<HTMLElement> => (
  <div key={type} className="m-tnm-sidebar__stop-card-description">
    <span className="m-tnm-sidebar__stop-route-name">
      <ModeIcon type={type} />
      {renderRoutesLabel(routes, type)}
    </span>
  </div>
);

interface Props {
  stop: Stop;
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
