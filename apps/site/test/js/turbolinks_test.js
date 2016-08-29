import { assert } from 'chai';
import { samePath } from '../../web/static/js/turbolinks';

describe('turbolinks', () => {
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
    });
  });
});
