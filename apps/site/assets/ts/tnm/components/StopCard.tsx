import React, { ReactElement, KeyboardEvent } from "react";
import { Stop, Route } from "./__tnm";
import { clickStopCardAction } from "../state";
import { Direction, directionIsEmpty } from "./Direction";
// @ts-ignore
import stationSymbol from "../../../static/images/icon-circle-t-small.svg";
// @ts-ignore
import accessibleIcon from "../../../static/images/icon-accessible-default.svg";

interface Props {
  stop: Stop;
  route: Route;
  dispatch: Function;
}

export const stopIsEmpty = (stop: Stop): boolean =>
  stop.directions.every(directionIsEmpty);

const renderSvg = (svg: string, className: string): JSX.Element => (
  <span
    className={className}
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: svg }}
  />
);

const renderStopIcon = (stop: Stop): JSX.Element =>
  stop["station?"] ? (
    renderSvg(stationSymbol, "m-tnm-sidebar__stop-marker")
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
  route,
  dispatch
}: Props): ReactElement<HTMLElement> | null => {
  const key = `${route.id}-${stop.id}`;

  if (stopIsEmpty(stop)) {
    return null;
  }

  const onClick = (): void => dispatch(clickStopCardAction(stop.id));

  return (
    <div
      role="button"
      tabIndex={0}
      className="m-tnm-sidebar__stop"
      onClick={onClick}
      onKeyPress={e => handleKeyPress(e, onClick)}
    >
      <div className="m-tnm-sidebar__stop-info">
        <a href={stop.href} className="m-tnm-sidebar__stop-name">
          {renderStopIcon(stop)}
          {stop.name}
          {!!stop.accessibility.length &&
            !stop.accessibility.includes("unknown") &&
            renderSvg(accessibleIcon, "m-tnm-sidebar__stop-accessible")}
        </a>
        <div className="m-tnm-sidebar__stop-distance">{stop.distance}</div>
      </div>
      {stop.directions.map(direction => (
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
