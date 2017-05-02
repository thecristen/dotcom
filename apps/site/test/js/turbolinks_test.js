import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { default as turbolinks, samePath } from '../../web/static/js/turbolinks';

describe('turbolinks', () => {
  describe('on turbolinks:render', () => {
    var $;
    jsdom();

    before(() => {
      $ = jsdom.rerequire('jquery');
      $("body").html(`
<div id="anchor" class="collapse">
  <a id="focused" href="" data-target="#anchor">link</a>
</div>
`);
      // not implemented in Node, so polyfill it
      window.requestAnimationFrame = process.nextTick;
      turbolinks($, window, document);
    });

    it("focuses the link child of the current anchor", (done) => {
      window.location.hash = "#anchor";
      document.getElementById("focused").addEventListener("focus", () => {
        done();
      }, {once: true});
      document.dispatchEvent(makeEvent('turbolinks:render'));
    });

    it("expands the link child of an anchor if it's a target", (done) => {
      window.location.hash = "#anchor";
      $.fn.collapse = function (event, arg) {
        // make sure we're showing the anchor
        assert.equal(event, 'show');
        assert.lengthOf(this, 1);
        assert.equal(this[0], document.getElementById("anchor"));
        done();
      };
      document.dispatchEvent(makeEvent('turbolinks:render'));
    });

    it("focuses an anchor directly", (done) => {
      window.location.hash = "#focused";
      document.getElementById("focused").addEventListener("focus", () => {
        done();
      }, {once: true});
      document.dispatchEvent(makeEvent('turbolinks:render'));
    });
  });

  describe("samePath", () => {
    it("true if they are equal", () => {
      assert.isTrue(samePath("http://localhost/1", "http://localhost/1"));
    });

    it("false if they are not equal", () => {
      assert.isFalse(samePath("http://localhost/1", "http://localhost/2"));
    });

    it("true if they have equal paths", () => {
      assert.isTrue(samePath("http://localhost/1?query", "http://localhost/1"));
    });

    it("false if first is only a prefix of second", () => {
      assert.isFalse(samePath("http://localhost/1/2", "http://localhost/1"));
      assert.isFalse(samePath("http://localhost/1", "http://localhost/1/2"));
    });
  });
});

function makeEvent(name) {
  const event = document.createEvent("HTMLEvents");
  event.initEvent(name, true, true);
  return event;
}
