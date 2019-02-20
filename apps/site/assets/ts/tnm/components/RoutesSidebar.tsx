import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import RouteSidebarHeader from "./RouteSidebarHeader";
import { Route, Stop } from "./__tnm";

interface Props {
  data: Route[];
  getOffset(): number;
  dispatch: Function;
  selectedStopId: string | null;
  shouldFilterStopCards: boolean;
  selectedStop: Stop | undefined;
}

interface State {
  offset: number;
}

const filterDataByStopId = (data: Route[], stopId: string): Route[] =>
  data.reduce((accumulator: Route[], route: Route): Route[] => {
    const stops = route.stops.filter(stop => stop.id === stopId);
    if (stops.length === 0) {
      return accumulator;
    }
    return accumulator.concat(Object.assign({}, route, { stops }));
  }, []);

export const filterData = (
  data: Route[],
  selectedStopId: string | null,
  shouldFilter: boolean
): Route[] => {
  if (shouldFilter === false || selectedStopId === null) {
    return data;
  }

  return filterDataByStopId(data, selectedStopId);
};

class RoutesSidebar extends React.Component<Props, State> {
  public constructor(props: Props) {
    super(props);
    this.onResize = this.onResize.bind(this);
    this.state = {
      offset: 0
    };
  }

  public componentDidMount(): void {
    window.addEventListener("resize", this.onResize);
    this.onResize();
  }

  public componentWillUnmount(): void {
    window.removeEventListener("resize", this.onResize);
  }

  private onResize(): void {
    const { getOffset } = this.props;
    this.setState({
      offset: getOffset()
    });
  }

  public render(): ReactElement<HTMLElement> | null {
    const {
      data,
      dispatch,
      selectedStopId,
      selectedStop,
      shouldFilterStopCards
    } = this.props;
    const { offset } = this.state;

    return data.length ? (
      <div className="m-tnm-sidebar" style={{ left: `${offset}px` }}>
        <RouteSidebarHeader selectedStop={selectedStop} dispatch={dispatch} />
        {filterData(data, selectedStopId, shouldFilterStopCards).map(route => (
          <RouteCard key={route.id} route={route} dispatch={dispatch} />
        ))}
      </div>
    ) : null;
  }
}

export default RoutesSidebar;
