import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import { Route, SVGMarkers } from "./__tnm";
import { iconStation, iconStop } from "../../../js/google-map/icons";

interface Props {
  data: Array<Route>;
  markers: SVGMarkers;
}

class RoutesSidebar extends React.Component<Props> {
  public static defaultProps: Props = {
    data: [],
    markers: {
      stopMarker: iconStop(),
      stationMarker: iconStation()
    }
  };

  private renderRouteCard(
    route: Route,
    markers: SVGMarkers
  ): ReactElement<any> {
    return <RouteCard key={route.id} route={route} markers={markers} />;
  }

  public render(): ReactElement<any> | null {
    const { data, markers } = this.props;
    return data.length ? (
      <div className="m-tnm-sidebar">
        {data.map(route => this.renderRouteCard(route, markers))}
      </div>
    ) : null;
  }
}

export default RoutesSidebar;
