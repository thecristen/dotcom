import tnmData from "../tnmData.json";
import { Route } from "../../components/__tnm";

export const createReactRoot = (): void => {
  document.body.innerHTML =
    '<div><div id="react-root"><div id="test"></div></div></div>';
};

export const importData = (): Route[] => JSON.parse(JSON.stringify(tnmData));
