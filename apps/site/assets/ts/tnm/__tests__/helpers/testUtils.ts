import tnmData from "../tnmData.json";
import tnmStopData from "../tnmStopData.json";
import { StopWithRoutes, TNMRoute } from "../../components/__tnm";

export const importData = (): TNMRoute[] => JSON.parse(JSON.stringify(tnmData));

export const importStopData = (): StopWithRoutes[] =>
  JSON.parse(JSON.stringify(tnmStopData));
