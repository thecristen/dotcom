import React, { ReactElement } from "react";
import { TNMHeadsign, TNMPredictionTime, TNMTime } from "./__tnm";

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
        {headsign.times.map(time => renderTime(time))}
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

const renderPrediction = (time: TNMPredictionTime): ReactElement<any> =>
  typeof time === "string" ? renderTimeString(time) : renderTimeArray(time);

const renderTimeString = (time: string): ReactElement<any> => (
  <div className="m-tnm-sidebar__prediction">{time}</div>
);

const renderTimeArray = (time: Array<string>): ReactElement<any> => {
  const [num, _space, mins] = time;
  return (
    <div className="m-tnm-sidebar__prediction">
      <div className="m-tnm-sidebar__prediction-number">{num}</div>
      <div className="m-tnm-sidebar__prediction-mins">{mins}</div>
    </div>
  );
};

const renderTime = (time: TNMTime) => {
  const { prediction, schedule } = time;
  return (
    <div key={time.schedule} className="m-tnm-sidebar__schedule">
      {prediction ? renderPrediction(prediction.time) : schedule}
    </div>
  );
};

export default Headsign;
