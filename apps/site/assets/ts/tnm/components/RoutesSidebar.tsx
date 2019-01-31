import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import { Route } from "./__tnm";

interface Props {
  data: Array<Route>;
}

class RoutesSidebar extends React.Component<Props> {
  public static defaultProps: Props = {
    data: []
  };

  private renderRouteCard(route: Route): ReactElement<any> {
    return <RouteCard key={route.id} route={route} />;
  }

  public render(): ReactElement<any> | null {
    const { data } = this.props;
    return data.length ? (
      <div className="m-tnm-sidebar">
        {data.map(route => this.renderRouteCard(route))}
      </div>
    ) : null;
  }
}

export default RoutesSidebar;
