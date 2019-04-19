import icon from "../icon";

it("generates a leaflet icon", () => {
  const iconClass = icon("abc");
  expect(iconClass.options.iconUrl).toBe("/images/icon-abc.svg");
});
