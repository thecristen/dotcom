import React, { ReactElement } from "react";
import { Stop, Mode } from "../../__v3api";
import { Dispatch, clickModeAction } from "../state";
import { TypedRoutes, RouteWithDirections } from "./__stop";
import RouteCard from "./RouteCard";
import { ModeFilter, modeByV3ModeType } from "../../components/ModeFilter";

interface Props {
  routes: TypedRoutes[];
  stop: Stop;
  selectedModes: Mode[];
  dispatch: Dispatch;
}

const includesMultipleModes = (typedRoutes: TypedRoutes[]): boolean =>
  typedRoutes.length > 1;

const allRoutes = (typedRoutes: TypedRoutes[]): RouteWithDirections[] =>
  typedRoutes.reduce(
    (acc: RouteWithDirections[], typeAndRoutes: TypedRoutes) =>
      acc.concat(typeAndRoutes.routes),
    []
  );

const availableModes = (typedRoutes: TypedRoutes[]): string[] =>
  // eslint-disable-next-line typescript/camelcase
  typedRoutes.map(({ group_name }) => group_name);

const filteredByModes = (
  routes: RouteWithDirections[],
  modes: Mode[]
): RouteWithDirections[] => {
  // If there are no selections or all selections, do not filter
  if (modes.length === 0 || modes.length === 3) return routes;

  return routes.filter(route =>
    modes.some(mode => modeByV3ModeType[route.route.type] === mode)
  );
};

const Departures = ({
  routes,
  stop,
  selectedModes,
  dispatch
}: Props): ReactElement<HTMLElement> => {
  const isModeSelected = (mode: Mode): boolean => selectedModes.includes(mode);

  const handleModeClick = (mode: Mode): void => dispatch(clickModeAction(mode));

  const filteredRoutes = filteredByModes(allRoutes(routes), selectedModes);

  return (
    <>
      <h2>Departures</h2>

      <div className="m-stop-page__departures">
        {includesMultipleModes(routes) && (
          <ModeFilter
            isModeSelected={isModeSelected}
            onModeClickAction={handleModeClick}
            modeButtonsToShow={availableModes(routes)}
          />
        )}

        {filteredRoutes.map(routeWithDirections => (
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
};

export default Departures;
