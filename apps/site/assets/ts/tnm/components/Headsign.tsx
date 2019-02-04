import React, { ReactElement } from "react";
import { TNMHeadsign, TNMTime } from "./__tnm";

interface Props {
  headsign: TNMHeadsign;
}

const Headsign = ({ headsign }: Props): ReactElement<any> => {
  return (
    <div className="m-tnm-sidebar__headsign-schedule">
      <div className="m-tnm-sidebar__headsign">
        {renderHeadsignName(headsign.name)}
      </div>
      <div className="m-tnm-sidebar__schedules">
        {headsign.times.map(time => renderTime(time, headsign.name))}
      </div>
    </div>
  );
};

const renderHeadsignName = (headsignName: string): ReactElement<any> => {
  if (headsignName.includes(" via ")) {
    const split = headsignName.split(" via ");
    return (
      <>
        <div className="m-tnm-sidebar__headsign-name">{split[0]}</div>
        <div className="m-tnm-sidebar__via">via {split[1]}</div>
      </>
    );
  }
  return <div className="m-tnm-sidebar__headsign-name">{headsignName}</div>;
};

const renderTime = (tnmTime: TNMTime, headsignName: string) => {
  const { prediction, schedule } = tnmTime;
  const time = prediction ? prediction.time : schedule;

  return (
    <div
      key={`${headsignName}-${schedule.join("")}`}
      className="m-tnm-sidebar__schedule"
    >
      {renderTimeArray(time)}
    </div>
  );
};

const renderTimeArray = (time: Array<string>): ReactElement<any> => {
  const [num, _space, mins] = time;
  return (
    <div className="m-tnm-sidebar__time">
      <div className="m-tnm-sidebar__time-number">{num}</div>
      <div className="m-tnm-sidebar__time-mins">{mins}</div>
    </div>
  );
};

export default Headsign;
