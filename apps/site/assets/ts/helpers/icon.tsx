import renderSvg from "./render-svg";
// @ts-ignore
import accessibleIconSvg from "../../static/images/icon-accessible-default.svg";
// @ts-ignore
import blueLineIconSvg from "../../static/images/icon-blue-line-default.svg";
// @ts-ignore
import busIconSvg from "../../static/images/icon-mode-bus-default.svg";
// @ts-ignore
import commuterRailIconSvg from "../../static/images/icon-mode-commuter-rail-default.svg";
// @ts-ignore
import greenLineIconSvg from "../../static/images/icon-green-line-default.svg";
// @ts-ignore
import greenBLineIconSvg from "../../static/images/icon-green-line-b-default.svg";
// @ts-ignore
import greenCLineIconSvg from "../../static/images/icon-green-line-c-default.svg";
// @ts-ignore
import greenDLineIconSvg from "../../static/images/icon-green-line-d-default.svg";
// @ts-ignore
import greenELineIconSvg from "../../static/images/icon-green-line-e-default.svg";
// @ts-ignore
import mattapanLineIconSvg from "../../static/images/icon-mattapan-line-default.svg";
// @ts-ignore
import orangeLineIconSvg from "../../static/images/icon-orange-line-default.svg";
// @ts-ignore
import parkingIconSvg from "../../static/images/icon-parking-default.svg";
// @ts-ignore
import redLineIconSvg from "../../static/images/icon-red-line-default.svg";

export const accessibleIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, accessibleIconSvg);

export const blueLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, blueLineIconSvg);

export const busIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, busIconSvg);

export const commuterRailIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, commuterRailIconSvg);

export const greenLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, greenLineIconSvg);

export const greenBLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, greenBLineIconSvg);

export const greenCLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, greenCLineIconSvg);

export const greenDLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, greenDLineIconSvg);

export const greenELineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, greenELineIconSvg);

export const mattapanLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, mattapanLineIconSvg);

export const orangeLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, orangeLineIconSvg);

export const parkingIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, parkingIconSvg);

export const redLineIcon = (className: string = ""): JSX.Element =>
  renderSvg(className, redLineIconSvg);
