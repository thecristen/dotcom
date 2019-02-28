import React, { ReactElement } from "react";
import { RouteType, TNMHeadsign, TNMTime, TNMPrediction } from "./__tnm";

interface Props {
  headsign: TNMHeadsign;
  routeType: RouteType;
  condensed: boolean;
}

const headsignClass = (condensed: boolean): string => {
  if (condensed === true) {
    return "m-tnm-sidebar__headsign-schedule m-tnm-sidebar__headsign-schedule--condensed";
  }
  return "m-tnm-sidebar__headsign-schedule";
};

const renderHeadsignName = ({
  headsign,
  routeType,
  condensed
}: Props): ReactElement<HTMLElement> => {
  const modifier = !condensed && routeType === 3 ? "small" : "large";

  const headsignNameClass = `m-tnm-sidebar__headsign-name m-tnm-sidebar__headsign-name--${modifier}`;

  if (headsign.name && headsign.name.includes(" via ")) {
    const split = headsign.name.split(" via ");
    return (
      <>
        <div className={headsignNameClass}>{split[0]}</div>
        <div className="m-tnm-sidebar__via">{`via ${split[1]}`}</div>
      </>
    );
  }
  return <div className={headsignNameClass}>{headsign.name}</div>;
};

const renderTrainName = (trainName: string): ReactElement<HTMLElement> => (
  <div className="m-tnm-sidebar__headsign-train">{trainName}</div>
);

const renderTimeCommuterRail = (
  time: string[],
  prediction: TNMPrediction | null
): ReactElement<HTMLElement> => (
  <div className="m-tnm-sidebar__time m-tnm-sidebar__time--commuter-rail">
    <div className="m-tnm-sidebar__time-number">{time.join("")}</div>
    <div className="m-tnm-sidebar__status">
      {`${prediction ? prediction.status : "On time"}${
        prediction && prediction.track ? ` track ${prediction.track}` : ""
      }`}
    </div>
  </div>
);

const renderTimeDefault = (time: string[]): ReactElement<HTMLElement> => (
  <div className="m-tnm-sidebar__time">
    <div className="m-tnm-sidebar__time-number">{time[0]}</div>
    <div className="m-tnm-sidebar__time-mins">{time[2]}</div>
  </div>
);

const renderTime = (
  tnmTime: TNMTime,
  headsignName: string,
  routeType: RouteType,
  idx: number
): ReactElement<HTMLElement> => {
  // eslint-disable-next-line typescript/camelcase
  const { prediction, scheduled_time } = tnmTime;
  // eslint-disable-next-line typescript/camelcase
  const time = prediction ? prediction.time : scheduled_time!;

  return (
    <div
      // eslint-disable-next-line typescript/camelcase
      key={`${headsignName}-${idx}`}
      className="m-tnm-sidebar__schedule"
    >
      {routeType === 2
        ? renderTimeCommuterRail(time, prediction)
        : renderTimeDefault(time)}
    </div>
  );
};

const Headsign = (props: Props): ReactElement<HTMLElement> => {
  const { headsign, routeType, condensed } = props;
  return (
    <div className={headsignClass(condensed)}>
      <div className="m-tnm-sidebar__headsign">
        {renderHeadsignName(props)}

        {routeType === 2 && renderTrainName(`Train ${headsign.train_number}`)}
      </div>
      <div className="m-tnm-sidebar__schedules">
        {headsign.times.map((time, idx) =>
          renderTime(time, headsign.name, routeType, idx)
        )}
      </div>
    </div>
  );
};

export default Headsign;
