import React, { ReactElement } from "react";
// @ts-ignore: Not typed
import GoogleMap from "../../../js/google-map-class";

interface Props {
  initialData: any;
  mapElementId: string;
}

class TransitNearMeMap extends React.Component<Props> {
  public componentDidMount(): void {
    const { mapElementId, initialData } = this.props;
    this.map = new GoogleMap(mapElementId, initialData);
    this.map.bind(this);
    if (initialData.markers.length > 0) {
      this.tightenBounds();
    }
  }

  /* eslint-disable typescript/no-explicit-any */
  public data: any;

  public map: any;
  /* eslint-enable typescript/no-explicit-any */

  public tightenBounds(): void {
    this.map.resetBounds(["current-location", "radius-west", "radius-east"]);
  }

  // eslint-disable-next-line
  public render(): ReactElement<any> {
    return <div />;
  }
}

export default TransitNearMeMap;
