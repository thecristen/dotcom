import React, { ReactElement } from "react";
import SelectContainer from "./schedule-finder/SelectContainer";
import { RoutePattern, DirectionId, Route } from "../../__v3api";

interface Props {
  directionId: DirectionId;
  route: Route;
  routePatterns: RoutePattern[];
}

const DirectionSelector = ({
  directionId,
  route,
  routePatterns
}: Props): ReactElement<HTMLElement> => {
  const directionName: string = route.direction_names[directionId];
  const directionDestination: string =
    route.direction_destinations[directionId];
  return (
    <div>
      <div className="u-small-caps" style={{ fontWeight: "bold" }}>
        {directionName}
      </div>
      <h3 style={{ marginTop: 0 }}>{directionDestination}</h3>
      {routePatterns.length > 1 && (
        <SelectContainer id="direction-selector" error={false}>
          <select>
            {routePatterns.map(pattern => (
              <option value={pattern.id}>
                {pattern.name} {pattern.typicality}{" "}
                {pattern.time_desc && `(${pattern.time_desc})`}
              </option>
            ))}
          </select>
        </SelectContainer>
      )}
    </div>
  );
};

export default DirectionSelector;
