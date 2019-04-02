import React, { ReactElement } from "react";
import { Stop } from "../../__v3api";
import { TypedRoutes, RouteWithDirections } from "./__stop";
import RouteCard from "./RouteCard";

interface Props {
  routes: TypedRoutes[];
  stop: Stop;
}

const allRoutes = (typedRoutes: TypedRoutes[]): RouteWithDirections[] =>
  typedRoutes.reduce(
    (acc: RouteWithDirections[], typeAndRoutes: TypedRoutes) =>
      acc.concat(typeAndRoutes.routes),
    []
  );

const Departures = ({ routes, stop }: Props): ReactElement<HTMLElement> => (
  <>
    <h2>Departures</h2>

    <div className="m-stop-page__departures">
      {allRoutes(routes).map(routeWithDirections => (
        <RouteCard
          key={routeWithDirections.route.id}
          route={routeWithDirections.route}
          directions={routeWithDirections.directions}
          stop={stop}
        />
      ))}
    </div>
  </>
);

export default Departures;
