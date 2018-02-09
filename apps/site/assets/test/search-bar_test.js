import { expect } from 'chai';
import jsdom from 'mocha-jsdom';
import Sifter from 'sifter';
import { doSetupSearch, siftStops, showResults, addButtonClasses, buttonList, SELECTORS, STYLE_CLASSES } from '../../assets/js/search-bar';

describe("search-bar", function() {
  jsdom();

  beforeEach(function() {
    document.body.innerHTML = `
      <label for="${SELECTORS.IDS.INPUT}">Search for a Station</label>
      <div id="search-bar-container" class="text-input-button-widget hidden-no-js">
        <input type="text" id="${SELECTORS.IDS.INPUT}" class="text-input-button-widget-input" placeholder="Enter station name"></input>
        <div class="clearfix"></div>
      </div>
      <div id="${SELECTORS.IDS.RESULT_LIST}">
        <h4 id="${SELECTORS.IDS.EMPTY_MSG}">No results match</h4>
        <a href="/stops/place-alfcl" data-name="Alewife">
          Alewife
          <span class="stop-features-list"></span>
        </a>
        <a href="/stops/place-davis" data-name="Davis">
          Davis
          <span class="stop-features-list"></span>
        </a>
        <a href="/stops/place-portr" data-name="Porter">
          Porter
          <span class="stop-features-list"></span>
        </a>
        <a href="/stops/place-hrvrd" data-name="Harvard">
          Harvard
          <span class="stop-features-list"></span>
        </a>
      </div>
    `;
  });

  describe("siftStops", function() {
    it("updates the search string with the key value from the event", function() {
      const data = [
        {name: "alewife"},
        {name: "alewife1"},
        {name: "davis"},
        {name: "porter"},
        {name: "harvard"}
      ];
      expect(typeof SELECTORS.IDS.INPUT).to.equal("string");
      const result = siftStops(data, "alewife");
      expect(result).to.have.a.lengthOf(2);
      expect(result[0].name).to.equal("alewife");
      expect(result[1].name).to.equal("alewife1");
    });
  });

  describe("addButtonClasses", function() {
    it("adds js selector classes to buttons", function() {
      expect(buttonList()).to.have.a.lengthOf(0);
      addButtonClasses();
      expect(buttonList()).to.have.a.lengthOf(4);
    });
  });

  function isVisible(btn) {
    return btn.style.display == "flex"
  }

  describe("showResults", function() {
    it("shows stops that match search", function() {
      addButtonClasses();
      expect(buttonList().filter(isVisible)).to.have.a.lengthOf(0); // all buttons start out hidden

      const el = document.getElementById(SELECTORS.IDS.INPUT);
      expect(el).to.be.an.instanceOf(window.HTMLInputElement);
      el.value = "Ale"
      showResults();

      const showing = buttonList().filter(isVisible)
      expect(showing).to.have.a.lengthOf(1);
      expect(showing[0].textContent).to.contain("Alewife");
    });
  });

  describe("setupSearch", function() {
    it("adds js classes and keyup event handler", function() {
      expect(buttonList()).to.have.a.lengthOf(0);
      doSetupSearch();
      expect(buttonList()).to.have.a.lengthOf(4);
      expect(buttonList().filter(isVisible)).to.have.a.lengthOf(0);
      const input = document.getElementById(SELECTORS.IDS.INPUT);
      input.value = "alewife";
      input.dispatchEvent(new window.Event("keyup"));
      expect(buttonList().filter(isVisible)).to.have.a.lengthOf(1);
    });
  });
});
