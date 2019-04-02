import React, { ReactElement, KeyboardEvent } from "react";
import { Direction as DirectionType, Route, Stop } from "../__v3api";
import { clickStopCardAction, Dispatch } from "../tnm/state";
import Direction from "./Direction";
import renderSvg from "../helpers/render-svg";
import { accessibleIcon } from "../helpers/icon";
// @ts-ignore
import stationSymbol from "../../static/images/icon-circle-t-small.svg";

interface Props {
  stop: Stop;
  directions: DirectionType[];
  route: Route;
  dispatch: Dispatch;
}

const renderStopIcon = (stop: Stop): JSX.Element =>
  stop["station?"] ? (
    renderSvg("m-tnm-sidebar__stop-marker", stationSymbol)
  ) : (
    <></>
  );

const handleKeyPress = (
  e: KeyboardEvent<HTMLDivElement>,
  onClick: Function
): void => {
  if (e.key === "Enter") {
    onClick();
  }
};

export const StopCard = ({
  stop,
  directions,
  route,
  dispatch
}: Props): ReactElement<HTMLElement> | null => {
  const onClick = (): void => dispatch(clickStopCardAction(stop.id));

  const key = `${route.id}-${stop.id}`;

  return (
    <div
      role="button"
      tabIndex={0}
      className="m-tnm-sidebar__route-stop"
      onClick={onClick}
      onKeyPress={e => handleKeyPress(e, onClick)}
    >
      <div className="m-tnm-sidebar__stop-info">
        <a href={stop.href} className="m-tnm-sidebar__stop-name">
          {renderStopIcon(stop)}
          {stop.name}
          {!!stop.accessibility.length &&
            !stop.accessibility.includes("unknown") &&
            accessibleIcon("m-tnm-sidebar__stop-accessible")}
        </a>
        <div className="m-tnm-sidebar__stop-distance">{stop.distance}</div>
      </div>
      {directions.map(direction => (
        <Direction
          key={`${key}-${direction.direction_id}`}
          direction={direction}
          route={route}
          stopId={stop.id}
        />
      ))}
    </div>
  );
};

export default StopCard;
