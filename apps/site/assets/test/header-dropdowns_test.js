import { expect } from "chai";
import jsdom from "mocha-jsdom";
import { initCarets } from "../../assets/js/header-dropdowns";
import sinon from "sinon";

describe("headerDropdowns", function() {
  jsdom();

  beforeEach(function() {
    document.body.innerHTML = `
      <div class="js-header-link">
        <div class="js-header-link__content">
          <div class="js-header-link__carets"></div>
        </div>
      </div>
    `;
  });

  it("adds toggle attributes and classes to header links", function() {
    const el = document.getElementsByClassName("js-header-link").item(0);
    initCarets();
    expect(el.getAttribute("data-toggle")).to.equal("collapse");
    expect(el.getAttribute("aria-expanded")).to.equal("false");
    expect(el.classList.contains("navbar-toggle")).to.be.true;
    expect(el.classList.contains("toggle-up-down")).to.be.true;
  });

  it("adds up/down carets", function() {
    initCarets();
    const el = document.getElementsByClassName("js-header-link__content").item(0);
    const caretContainer = el.children.item(0);
    expect(caretContainer).to.be.an.instanceOf(window.HTMLDivElement);
    expect(caretContainer.children).to.have.lengthOf(2);
    expect(caretContainer.children.item(0).classList.contains("fa-angle-up")).to.be.true;
    expect(caretContainer.children.item(1).classList.contains("fa-angle-down")).to.be.true;
  });
});
