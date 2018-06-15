import { expect } from "chai";
import jsdom from "mocha-jsdom";
import headerDropdowns from "../../assets/js/header-dropdowns";
import sinon from "sinon";

describe("headerDropdowns", function() {
  jsdom();

  beforeEach(function() {
    document.body.innerHTML = `
      <div class="js-header-link">
        <div class="js-header-link__content"></div>
      </div>
    `;
  });

  it("adds toggle attributes and classes to header links", function() {
    const el = document.getElementsByClassName("js-header-link")[0];
    headerDropdowns();
    expect(el.getAttribute("data-toggle")).to.equal("collapse");
    expect(el.getAttribute("aria-expanded")).to.equal("false");
    expect(el.classList.contains("navbar-toggle")).to.be.true;
    expect(el.classList.contains("toggle-up-down")).to.be.true;
  });

  it("adds up/down carets", function() {
    headerDropdowns();
    const el = document.getElementsByClassName("js-header-link__content")[0];
    const caretContainer = el.children.item(0);
    expect(caretContainer).to.be.an.instanceOf(window.HTMLDivElement);
    expect(caretContainer.classList.contains("nav-link-arrows")).to.be.true;
    expect(caretContainer.children).to.have.lengthOf(2);
    expect(caretContainer.children.item(0).classList.contains("fa-angle-up")).to.be.true;
    expect(caretContainer.children.item(1).classList.contains("fa-angle-down")).to.be.true;
  });
});
