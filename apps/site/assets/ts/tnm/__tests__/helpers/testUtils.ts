import tnmData from "../tnmData.json";
import tnmStopData from "../tnmStopData.json";
import { Route, StopWithRoutes } from "../../components/__tnm";

export const createReactRoot = (): void => {
  document.body.innerHTML =
    '<div><div id="react-root"><div id="test"></div></div></div>';
};

export const importData = (): Route[] => JSON.parse(JSON.stringify(tnmData));

export const importStopData = (): StopWithRoutes[] =>
  JSON.parse(JSON.stringify(tnmStopData));
