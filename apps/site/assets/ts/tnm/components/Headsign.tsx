import React, { ReactElement } from "react";
import { RouteType } from "../../__v3api";
import { TNMHeadsign, TNMTime } from "./__tnm";

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

const crDelayedTime = (data: TNMTime): ReactElement<HTMLElement> => (
  <>
    <div className="m-tnm-sidebar__time-number--delayed">
      {data.scheduled_time!.join("")}
    </div>
    <div className="m-tnm-sidebar__time-number">
      {data.prediction && data.prediction.time.join("")}
    </div>
  </>
);

const crTime = (data: TNMTime): ReactElement<HTMLElement> => {
  // eslint-disable-next-line typescript/camelcase
  const { delay, prediction, scheduled_time } = data;
  if (delay > 0 && prediction) {
    return crDelayedTime(data);
  }

  // eslint-disable-next-line typescript/camelcase
  const time = prediction ? prediction.time : scheduled_time;

  return <div className="m-tnm-sidebar__time-number">{time!.join("")}</div>;
};

const crStatus = ({ delay, prediction }: TNMTime): string => {
  if (delay > 0) {
    return `Delayed ${delay} min`;
  }

  if (prediction && prediction.status) {
    return prediction.status;
  }

  return "On time";
};

const renderTimeCommuterRail = (data: TNMTime): ReactElement<HTMLElement> => (
  <div className="m-tnm-sidebar__time m-tnm-sidebar__time--commuter-rail">
    {crTime(data)}
    <div className="m-tnm-sidebar__status">
      {`${crStatus(data)}${
        data.prediction && data.prediction.track
          ? ` track ${data.prediction.track}`
          : ""
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
        ? renderTimeCommuterRail(tnmTime)
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
