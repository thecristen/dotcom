import React, { ReactElement } from "react";
import deepEqual from "fast-deep-equal";
import Marker from "./Marker";
import { MapData, MarkerData } from "../../app/googleMaps/__googleMaps";
import { Mode } from "../../__v3api";
import { clickMarkerAction, SelectedStopType, Dispatch } from "../state";
import { setMapDefaults } from "../../app/googleMaps/helpers";
import { StopWithRoutes } from "./__tnm";

interface Props {
  initialData: MapData;
  mapElementId: string;
  dispatch: Dispatch;
  selectedStopId: SelectedStopType;
  selectedModes: Mode[];
  shouldCenterMapOnSelectedStop: boolean;
  shouldFilterMarkers: boolean;
  stopData: StopWithRoutes[];
}

class TransitNearMeMap extends React.Component<Props> {
  public map: google.maps.Map | null = null;

  public componentDidMount(): void {
    const { mapElementId, initialData, dispatch } = this.props;
    const mapElement = document.getElementById(mapElementId);
    if (!mapElement) return;

    const map = new window.google.maps.Map(mapElement);
    map.addListener("click", () => {
      dispatch(clickMarkerAction(null));
    });
    setMapDefaults(map, initialData);
    this.map = map;
    this.setBounds();

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
      initialData,
      shouldFilterMarkers,
      selectedModes,
      stopData
    } = this.props;
    if (this.map) {
      const markers = initialData.markers.map((marker: MarkerData) => (
        <Marker
          key={marker.id}
          data={marker}
          map={this.map!}
          dispatch={dispatch}
          stopData={stopData.find(stop => stop.stop.stop.id === marker.id)}
          isSelected={selectedStopId === marker.id}
          shouldFilterMarkers={shouldFilterMarkers}
          selectedModes={selectedModes}
        />
      ));

      // eslint-disable-next-line no-unused-expressions
      shouldCenterMapOnSelectedStop && selectedStopId && this.centerMap();

      return <>{markers}</>;
    }
    return null;
  }
}

export default React.memo(TransitNearMeMap, deepEqual);
