import * as TransitNearMe from "../tnm/transit-near-me";
import TransitNearMeSearch from "../tnm/search";

describe("TransitNearMe", () => {
  beforeEach(() => {
    window.decodeURIComponent = (string: string) =>
      string.replace(/%20/g, " ").replace(/%26/g, "&");

    const {
      container,
      input,
      resetButton,
      goBtn
    } = TransitNearMeSearch.SELECTORS;

    document.body.innerHTML = `
      <div id='address-search-message'></div>
      <div id="${container}">
        <input id="${input}"></input>
        <div id="${resetButton}"></div>
        <button id ="${goBtn}"></button>
      </div>
    `;
  });

  describe("onLoad", () => {
    it("requests the user's location", () => {
      const geo = jest.fn();
      // @ts-ignore
      window.navigator.geolocation = { getCurrentPosition: geo };

      const data = {
        data: {
          url: "/transit-near-me"
        }
      };
      TransitNearMe.onLoad(data as TransitNearMe.GeolocationData);
      expect(geo).toBeCalled();
    });

    it('does not request location if query includes "address"', () => {
      const geo = jest.fn();
      // @ts-ignore
      window.navigator.geolocation = { getCurrentPosition: geo };
      const data = {
        data: {
          url: "/transit-near-me?location[address]=42,-71"
        }
      };
      TransitNearMe.onLoad(data as TransitNearMe.GeolocationData);
      // @ts-ignore
      expect(geo.mock.calls.length).toBe(0);
    });
  });

  describe("onLocation", () => {
    it("sets lat/lng params and refreshes the page", () => {
      window.Turbolinks = { visit: jest.fn() };
      const geo = {
        coords: {
          latitude: 42,
          longitude: -71
        }
      };
      TransitNearMe.onLocation(geo as Position);
      expect(window.Turbolinks.visit).toBeCalledWith(
        "http:?latitude=42&longitude=-71"
      );
    });
  });
});
