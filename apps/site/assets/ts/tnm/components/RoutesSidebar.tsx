import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import { Route, SVGMarkers } from "./__tnm";
import { iconStation, iconStop } from "../../../js/google-map/icons";

interface Props {
  data: Route[];
  markers: SVGMarkers;
  getOffset(): number;
}

interface State {
  offset: number;
}

class RoutesSidebar extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.onResize = this.onResize.bind(this);
    this.state = {
      offset: 0
    };
  }

  public static defaultProps: Props = {
    data: [],
    getOffset: () => 0,
    markers: {
      stopMarker: "",
      stationMarker: ""
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
      <div className="m-tnm-sidebar" style={{ left: `${this.state.offset}px` }}>
        {data.map(route => this.renderRouteCard(route, markers))}
      </div>
    ) : null;
  }

  componentDidMount() {
    window.addEventListener("resize", this.onResize);
    this.onResize();
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.onResize);
  }

  onResize() {
    this.setState({
      offset: this.props.getOffset()
    });
  }
}

export default RoutesSidebar;
