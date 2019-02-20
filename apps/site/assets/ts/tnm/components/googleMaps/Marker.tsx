import React, { ReactElement } from "react";
import { MarkerData } from "../__tnm";
import { clickMarkerAction, clickCurrentLocationAction } from "../../state";
import { buildMarkerIcon } from "./helpers";

interface Props {
  map: google.maps.Map;
  data: MarkerData;
  isSelected: boolean;
  dispatch: Function;
}

const buildMarkerOpts = (data: MarkerData): google.maps.MarkerOptions => {
  const position = new google.maps.LatLng(data.latitude, data.longitude);
  const icon = buildMarkerIcon(data, false);

  return {
    position,
    icon,
    zIndex: data.z_index
  };
};

class Marker extends React.Component<Props> {
  public marker: google.maps.Marker | null = null;

  public infoWindow: google.maps.InfoWindow | null = null;

  public componentDidMount(): void {
    const { data, map } = this.props;
    const markerOpts = buildMarkerOpts(data);
    this.marker = new window.google.maps.Marker(markerOpts);
    this.marker!.setMap(map);

    this.marker!.addListener("click", this.handleMarkerClick);

    const content = data.tooltip;
    this.infoWindow = new window.google.maps.InfoWindow({ content });
    this.infoWindow!.addListener("closeclick", this.handleInfoWindowClick);
  }

  public componentWillUnmount(): void {
    this.marker!.setMap(null);
    this.marker = null;
  }

  public handleMarkerClick = () => {
    const { data, dispatch } = this.props;
    const clickAction =
      data.id === "current-location"
        ? clickCurrentLocationAction
        : clickMarkerAction;
    dispatch(clickAction(data.id));
  };

  public handleInfoWindowClick = () => {
    const { dispatch } = this.props;
    dispatch(clickMarkerAction(null));
  };

  public render(): ReactElement<HTMLElement> | null {
    const { data, isSelected, map } = this.props;
    if (this.marker) {
      const icon = buildMarkerIcon(data, isSelected);
      /* eslint-disable no-unused-expressions */
      icon ? this.marker!.setIcon(icon) : null;
      isSelected
        ? this.infoWindow!.open(map!, this.marker!)
        : this.infoWindow!.close();
      /* eslint-enable no-unused-expressions */
    }
    return <div className={data.id} />;
  }
}

export default Marker;
