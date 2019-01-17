import { expect } from "chai";
import jsdom from "mocha-jsdom";
import sinon from "sinon";
import {
  addPlaceholder,
  animatePlaceholder,
  run,
  paused,
  placeholderId
} from "../animated-placeholder";

describe("animated-placeholder", function() {
  jsdom();
  const placeholders = [
    "placeholder 1",
    "placeholder 2",
    "placeholder 3"
  ];

  beforeEach(function() {
    paused["input"] = false;
    document.body.innerHTML = `
      <input id="input">
    `;
    window.$ = jsdom.rerequire("jquery");
    window.requestAnimationFrame = sinon.spy();
  });

  describe("addPlaceholder", function() {
    it("adds the placeholder div to the page if it doesn't already exist", function() {
      const result = addPlaceholder("input");
      expect(result).to.equal(true);
      const placeholder = document.getElementById(placeholderId);
      expect(placeholder).to.be.an.instanceOf(window.HTMLDivElement);
      expect(placeholder.classList.contains("c-form__animated-placeholder")).to.equal(true);
    });

    it("does not add another placeholder if one already exists", function() {
      const placeholder = document.createElement("div");
      placeholder.id = placeholderId;
      document.body.appendChild(placeholder);
      expect(addPlaceholder("input")).to.equal(false);
    });
  });

  describe("run", function() {
    // run() will return a jQuery object if the text is getting updated,
    // otherwise it calls requestAnimationFrame to try the function again

    it("updates the placeholder text if input is empty", function() {
      addPlaceholder("input");
      const result = run("input", placeholders, 0, 100);
      expect(result.attr("id")).to.equal(placeholderId);
    });

    it("calls window.requestAnimationFrame to rerun if input is not empty", function() {
      addPlaceholder("input");
      window.$("#input").val("hello world");
      run("input", placeholders, 0, 100);
      expect(window.requestAnimationFrame.called).to.be.true;
    });

    it("calls window.requestAnimationFrame to rerun if paused is true", function() {
      addPlaceholder("input");
      paused["input"] = true;
      run("input", placeholders, 0, 100);
      expect(window.requestAnimationFrame.called).to.be.true;
    });
  });

  describe("animatePlaceholders", function() {
    it("adds placeholder and calls run()", function() {
      expect(document.getElementsByClassName("c-form__input--with-animated-placeholder").item(0)).to.equal(null);
      const result = animatePlaceholder("input", placeholders, 100);
      const input = document.getElementById("input");
      expect(input.classList.contains("c-form__input--with-animated-placeholder")).to.be.true;
      expect(result.attr("id")).to.equal(placeholderId);
    });

    it("does not add placeholder if input isn't found", function() {
      const result = animatePlaceholder("fail", placeholders, 100);
      expect(result).to.equal(false);
      expect(document.getElementById(placeholderId)).to.equal(null);
    });
  });
});
