import jsdom from "mocha-jsdom";
import { expect, assert } from "chai";
import * as QueryStringHelpers from "../../assets/js/query-string-helpers";

describe("QueryStringHelpers", () => {
  describe("parseParams", () => {
    it("turns an object into a query string", () => {
      expect(QueryStringHelpers.parseParams({foo: "bar", bing: "bong"})).to.equal("?foo=bar&bing=bong");
    });

    it("replaces all spaces with +", () => {
      expect(QueryStringHelpers.parseParams({foo: "bar baz bat", bing: "bong"})).to.equal("?foo=bar+baz+bat&bing=bong");
    });

    it("returns an empty string if object has no values", () => {
      expect(QueryStringHelpers.parseParams({})).to.equal("");
    });
  });

  describe("parseQuery", () => {
    it("turns a query string into an object", () => {
      expect(QueryStringHelpers.parseQuery("?foo=bar&bing=bong")).to.deep.equal({foo: "bar", bing: "bong"});
    });

    it("replaces all spaces with +", () => {
      expect(QueryStringHelpers.parseQuery("?foo=bar+baz+bat&bing=bong")).to.deep.equal({foo: "bar baz bat", bing: "bong"});
    });

    it("returns an empty string if object has no values", () => {
      expect(QueryStringHelpers.parseQuery("")).to.deep.equal({});
    });

  });
});
