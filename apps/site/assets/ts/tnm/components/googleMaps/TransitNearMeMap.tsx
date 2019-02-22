import React, { ReactElement } from "react";
import Marker from "./Marker";
import { MapData, MarkerData } from "../__tnm";
import { clickMarkerAction, SelectedStopType } from "../../state";
import mapStyles from "../../../../js/google-map/styles";

interface Props {
  initialData: MapData;
  mapElementId: string;
  dispatch: Function;
  selectedStopId: SelectedStopType;
  shouldCenterMapOnSelectedStop: boolean;
}

class TransitNearMeMap extends React.Component<Props> {
  public map: google.maps.Map | null = null;

  public componentDidMount(): void {
    const { mapElementId, initialData, dispatch } = this.props;
    const mapElement = document.getElementById(mapElementId);
    if (!mapElement) return;

    const options = {
      center: new window.google.maps.LatLng(
        initialData.default_center.latitude,
        initialData.default_center.longitude
      )
    };
    const map = new window.google.maps.Map(mapElement, options);
    map.addListener("click", () => {
      dispatch(clickMarkerAction(null));
    });
    const styles = mapStyles as google.maps.MapTypeStyle[];
    // Hide stop icons on the transit layer
    styles.push({
      featureType: "transit",
      elementType: "labels.icon",
      stylers: [{ visibility: "off" }]
    });
    map.setOptions({ styles });
    map.setZoom(initialData.zoom || 17);
    this.map = map;

    this.setBounds();
    if (initialData.layers.transit) {
      const layer = new window.google.maps.TransitLayer();
      layer!.setMap(map);
    }

    this.forceUpdate();
  }

  public setBounds(): void {
    const halfMile = 0.008333;
    const { initialData } = this.props;
    const currentLocation = initialData.markers.find(
      (marker: MarkerData) => marker.id === "current-location"
    );

    if (currentLocation) {
      const east = new google.maps.LatLng(
        currentLocation!.latitude + halfMile,
        currentLocation!.longitude
      );
      const west = new google.maps.LatLng(
        currentLocation!.latitude - halfMile,
        currentLocation!.longitude
      );
      const bounds = new window.google.maps.LatLngBounds();

      bounds.extend(east);
      bounds.extend(west);
      this.map!.fitBounds(bounds);
    }
  }

  public centerMap(): void {
    const { initialData, selectedStopId } = this.props;
    const marker = initialData.markers.find(m => m.id === selectedStopId);
    this.map!.setCenter(
      new google.maps.LatLng(marker!.latitude, marker!.longitude)
    );
  }

  public render(): ReactElement<HTMLElement> | null {
    const {
      dispatch,
      selectedStopId,
      shouldCenterMapOnSelectedStop,
      initialData
    } = this.props;
    if (this.map) {
      const markers = initialData.markers.map((marker: MarkerData) => {
        const isSelected = selectedStopId === marker.id;

        return (
          <Marker
            key={marker.id}
            data={marker}
            map={this.map!}
            dispatch={dispatch}
            isSelected={isSelected}
          />
        );
      });

      // eslint-disable-next-line no-unused-expressions
      shouldCenterMapOnSelectedStop && selectedStopId && this.centerMap();

      return <>{markers}</>;
    }
    return null;
  }
}

export default TransitNearMeMap;
