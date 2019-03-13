import React, { ReactElement } from "react";
import StopPageData from "./__stop";
import Sidebar from "./Sidebar";

interface Props {
  stopPageData: StopPageData;
}

export default ({
  stopPageData: { stop }
}: Props): ReactElement<HTMLElement> => (
  <>
    <div className="breadcrumb-container">
      <div className="container">
        <span className="focusable-sm-down">
          <a href="/">Home</a>
          <i className="fa fa-angle-right" aria-hidden="true" />
        </span>
        <span>
          <a href="/stops/subway">Stations</a>
          <i className="fa fa-angle-right" aria-hidden="true" />
        </span>
        {stop.name}
      </div>
    </div>
    <div className="station__header">
      <div className="station__header-container">
        <h1 className="station__name station__name--upcase">{stop.name}</h1>
        <div className="h6 station__header-features" />
        <div className="header-tabs" />
      </div>
    </div>
    <div className="station__details">
      <div className="station__details-container">Station Details</div>
    </div>
    <div className="station__hero">
      <div className="station__hero-map" />
      <div className="station__hero-photo" />
    </div>
    <div className="container">
      <div className="page-section">
        <div className="row">
          <div className="col-lg-8 col-lg-offset-1">Main Column</div>
          <div className="col-lg-3">
            <Sidebar />
          </div>
        </div>
      </div>
    </div>
  </>
);
