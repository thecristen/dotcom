import React, { ReactElement } from "react";
import { Stop, Route } from "../../v3api";
import TabComponent from "./Tab";
import { Tab, TypedRoutes } from "./__stop";
import {
  accessibleIcon,
  parkingIcon,
  redLineIcon,
  mattapanLineIcon,
  orangeLineIcon,
  blueLineIcon,
  greenLineIcon,
  greenBLineIcon,
  greenELineIcon,
  greenDLineIcon,
  greenCLineIcon,
  busIcon,
  commuterRailIcon
} from "../../helpers/icon";

interface Props {
  stop: Stop;
  routes: TypedRoutes[];
  tabs: Tab[];
  zoneNumber: string;
}

interface ModeIconType {
  [propName: string]: ReactElement<HTMLElement>;
}

const subwayModeIds = [
  "Blue",
  "Green",
  "Green-B",
  "Green-C",
  "Green-D",
  "Green-E",
  "Mattapan",
  "Orange",
  "Red"
];

const accessible = ({
  accessibility
}: Stop): ReactElement<HTMLElement> | false =>
  accessibility.includes("accessible") && (
    <a href="#accessibility" className="station__header-feature">
      <span className="station__header-icon">
        {accessibleIcon("c-svg__icon-accessible-default")}
      </span>
    </a>
  );

// eslint-disable-next-line typescript/camelcase
const parking = ({ parking_lots }: Stop): ReactElement<HTMLElement> | false =>
  // eslint-disable-next-line typescript/camelcase
  parking_lots.length > 0 && (
    <a href="#parking" className="station__header-feature">
      <span className="station__header-icon">
        {parkingIcon("c-svg__icon-parking-default")}
      </span>
    </a>
  );

const modeType = (modeId: string): string => {
  if (modeId.startsWith("CR-")) return "CR";

  if (subwayModeIds.includes(modeId)) return modeId;

  return "Bus";
};

const modeIcon = (modeId: string): JSX.Element | undefined => {
  if (modeId.startsWith("CR-"))
    return commuterRailIcon("c-svg__icon-commuter-rail-default");
  if (modeId === "Blue") return blueLineIcon("c-svg__icon-blue-line-default");
  if (modeId === "Green")
    return greenLineIcon("c-svg__icon-green-line-default");
  if (modeId === "Green-B")
    return greenBLineIcon("c-svg__icon-green-b-line-default");
  if (modeId === "Green-C")
    return greenCLineIcon("c-svg__icon-green-c-line-default");
  if (modeId === "Green-D")
    return greenDLineIcon("c-svg__icon-green-d-line-default");
  if (modeId === "Green-E")
    return greenELineIcon("c-svg__icon-green-e-line-default");
  if (modeId === "Mattapan")
    return mattapanLineIcon("c-svg__icon-mattapan-line-default");
  if (modeId === "Orange")
    return orangeLineIcon("c-svg__icon-orange-line-default");
  if (modeId === "Red") return redLineIcon("c-svg__icon-red-line-default");

  return busIcon("c-svg__icon-bus-default");
};

const modeLink = (modeId: string): string => {
  if (modeId.startsWith("CR-"))
    return "/stops/place-sstat?tab=departures#commuter-rail-schedule";
  if (subwayModeIds.includes(modeId))
    return "/stops/place-sstat?tab=departures#subway-schedule";

  return "/stops/place-sstat?tab=departures#bus-schedule";
};

const modeIconFeature = ({ id }: Route): ReactElement<HTMLElement> => (
  <a href={modeLink(id)} key={modeType(id)} className="station__header-feature">
    <span className="station__header-icon">{modeIcon(id)}</span>
  </a>
);

const iconableRoutesForType = ({
  // eslint-disable-next-line typescript/camelcase
  group_name,
  routes
}: TypedRoutes): Route[] => {
  // eslint-disable-next-line typescript/camelcase
  if (group_name === "subway") return routes;

  return [routes[0]];
};

const iconableRoutes = (typedRoutes: TypedRoutes[]): Route[] =>
  typedRoutes.reduce(
    (acc: Route[], typeAndRoutes: TypedRoutes) =>
      acc.concat(iconableRoutesForType(typeAndRoutes)),
    []
  );

const modes = (
  typedRoutes: TypedRoutes[]
): ReactElement<HTMLElement> | null => (
  <>{iconableRoutes(typedRoutes).map(route => modeIconFeature(route))}</>
);

const crZone = (zoneNumber: string): ReactElement<HTMLElement> | false =>
  !!zoneNumber &&
  zoneNumber.length > 0 && (
    <a
      href="/stops/place-sstat?tab=info#commuter-fares"
      className="station__header-feature"
    >
      <span className="station__header-icon c-icon__cr-zone">
        {`Zone ${zoneNumber}`}
      </span>
    </a>
  );

const features = (
  stop: Stop,
  routes: TypedRoutes[],
  zoneNumber: string
): ReactElement<HTMLElement> => (
  <div className="station__header-features">
    {modes(routes)}
    {crZone(zoneNumber)}
    {accessible(stop)}
    {parking(stop)}
  </div>
);

const Header = ({
  stop,
  routes,
  tabs,
  zoneNumber
}: Props): ReactElement<HTMLElement> => (
  <div className="station__header">
    <div className="station__header-container">
      <h1 className="station__name station__name--upcase">{stop.name}</h1>

      {features(stop, routes, zoneNumber)}

      <div className="header-tabs">
        {tabs.map(tab => (
          <TabComponent key={tab.id} tab={tab} />
        ))}
      </div>
    </div>
  </div>
);

export default Header;
