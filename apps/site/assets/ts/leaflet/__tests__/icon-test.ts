import icon from "../icon";

it("generates a leaflet icon", () => {
  const iconClass = icon("abc");
  expect(iconClass).not.toEqual(undefined);
  expect(iconClass!.options.iconUrl).toBe("/images/icon-abc.svg");
});
