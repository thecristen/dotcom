import React from "react";
import ReactDOM from "react-dom";
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

  public render(): null {
    return null;
  }
}

const render = (): void => {
  const dataEl = document.getElementById("js-tnm-map-dynamic-data");
  if (dataEl) {
    const id = dataEl.getAttribute("data-for") as string;
    const initialData = JSON.parse(dataEl.innerHTML);
    ReactDOM.render(
      <div className="m-tnm__map">
        <div id={id} />
        <TransitNearMeMap mapElementId={id} initialData={initialData} />
      </div>,
      document.getElementById("react-root")
    );
  }
};

export default render;
