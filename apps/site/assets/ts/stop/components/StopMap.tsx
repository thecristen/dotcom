import React, { ReactElement } from "react";
import { setMapDefaults } from "../../app/googleMaps/helpers";
import Marker from "../../app/googleMaps/Marker";
import { MarkerData } from "../../app/googleMaps/__googleMaps";
import { StopMapData } from "./__stop";
import { clickMarkerAction, SelectedStopType, Dispatch } from "../state";

interface Props {
  initialData: StopMapData;
  mapElementId: string;
  dispatch: Dispatch;
  selectedStopId: SelectedStopType;
}

class StopMap extends React.Component<Props> {
  public map: google.maps.Map | null = null;

  public componentDidMount(): void {
    const { mapElementId, initialData, dispatch } = this.props;
    const mapData = initialData.map_data;
    const mapElement = document.getElementById(mapElementId);
    if (!mapElement) return;

    const map = new window.google.maps.Map(mapElement);
    map.addListener("click", () => {
      dispatch(clickMarkerAction(null));
    });
    setMapDefaults(map, mapData);
    this.map = map;

    this.centerMap();
    this.forceUpdate();
  }

  public centerMap(): void {
    const { initialData } = this.props;
    const marker = initialData.map_data.markers.find(
      (m: MarkerData) => m.id === "current-stop"
    );
    this.map!.setCenter(
      new google.maps.LatLng(marker!.latitude, marker!.longitude)
    );
  }

  public render(): ReactElement<HTMLElement> | null {
    const { initialData, dispatch, selectedStopId } = this.props;
    if (this.map) {
      return (
        <>
          {initialData.map_data.markers.map((marker: MarkerData) => (
            <Marker
              key={marker.id}
              data={marker}
              map={this.map!}
              dispatch={dispatch}
              isSelected={selectedStopId === marker.id}
            />
          ))}
        </>
      );
    }
    return null;
  }
}

export default StopMap;
