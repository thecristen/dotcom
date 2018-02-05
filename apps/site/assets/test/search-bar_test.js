import { expect } from 'chai';
import jsdom from 'mocha-jsdom';
import Sifter from 'sifter';
import { setupSearch, siftStops } from '../../assets/js/search-bar';

describe.only("search-bar", function() {
  jsdom();

  beforeEach(function() {
    document.body.innerHTML = `
      <label for="search-bar">Search for a Station</label>
      <div class="text-input-button-widget hidden-no-js">
        <input type="text" id="search-bar" class="text-input-button-widget-input" placeholder="Enter station name"></input>
        <div class="clearfix"></div>
      </div>
      <div id="search-bar__results">
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
      document.getElementById("search-bar").value = "alewife"
      const result = siftStops(data);
      expect(result).to.have.a.lengthOf(2);
      expect(result[0].name).to.equal("alewife");
      expect(result[1].name).to.equal("alewife1");
    });
  });

  describe("setupSearch", function() {
    it("builds a list of stops on keyup", function() {
      setupSearch()
      const resultContainer = document.getElementById("search-bar__results")
      expect(resultContainer).to.be.an.instanceOf(window.HTMLElement);
      expect(resultContainer.children).to.have.a.lengthOf(4);
      const el = document.getElementById("search-bar");
      expect(el).to.be.an.instanceOf(window.HTMLInputElement);
      el.value = "ale"
      el.dispatchEvent(new window.Event("keyup"));
      const showing = Array.from(resultContainer.children).filter(el => {
        return el.classList.contains("c-search-bar__result--hidden") == false
      })
      expect(showing).to.have.a.lengthOf(1);
      expect(resultContainer.children[0].textContent).to.contain("Alewife");
    });
  });
});
