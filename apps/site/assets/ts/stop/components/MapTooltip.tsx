import React, { ReactElement } from "react";
import { Stop, Route } from "../../__v3api";
import StopCard from "./StopCard";

interface Props {
  stop: Stop;
  routes: Route[];
}

const MapTooltip = ({ stop, routes }: Props): ReactElement<HTMLElement> => (
  <StopCard routes={routes} stop={stop} />
);

export default MapTooltip;
