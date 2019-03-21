import React, { ReactElement } from "react";
import RoutePillList from "./RoutePillList";
import { TypedRoutes } from "./__stop";

interface Props {
  routes: TypedRoutes[];
}

const AddressBlock = ({ routes }: Props): ReactElement<HTMLElement> => (
  <div className="m-stop-page__address-block">
    <div className="u-small-caps">Address</div>

    <RoutePillList routes={routes} />
  </div>
);

export default AddressBlock;
