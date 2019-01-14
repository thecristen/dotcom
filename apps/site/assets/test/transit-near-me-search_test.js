import { expect } from "chai";
import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { TransitNearMeSearch } from "../../assets/js/transit-near-me/search";

describe("TransitNearMeSearch", () => {
  jsdom();

  beforeEach(() => {
    window.autocomplete = jsdom.rerequire("autocomplete.js");
    window.jQuery = jsdom.rerequire("jquery");

    const {
      container,
      input,
      resetButton,
      goBtn,
      latitude,
      longitude
    } = TransitNearMeSearch.SELECTORS;

    document.body.innerHTML = `
      <div id="address-search-message"></div>
      <form id="${container}">
        <input id="${input}"></input>
        <div id="${resetButton}"></div>
        <button id ="${goBtn}"></button>
        <input type="text" id="${latitude}" />
        <input type="text" id="${longitude}" />
      </form>
    `;
  });

  describe("constructor", () => {
    it("initializes a TransitNearMeSearch instance", () => {
      const search = new TransitNearMeSearch();
      expect(search).to.be.an.instanceOf(TransitNearMeSearch);
    });
  });

  describe("showLocation", () => {
    it("submits the form with lat, lng, and formatted address", () => {
      const search = new TransitNearMeSearch();
      search.submit = sinon.spy();
      search.showLocation(42.1, -71.2, "10 Park Plaza, Boston MA");
      expect(search.submit.called).to.be.true;
      const {
        input,
        latitude,
        longitude
      } = TransitNearMeSearch.SELECTORS;
      expect(document.getElementById(input).value).to.equal("10 Park Plaza, Boston MA")
      expect(document.getElementById(latitude).value).to.equal("42.1")
      expect(document.getElementById(longitude).value).to.equal("-71.2")
    });
  });
});
