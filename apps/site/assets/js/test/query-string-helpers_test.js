import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect, assert } from "chai";
import * as QueryStringHelpers from "../query-string-helpers";

describe("QueryStringHelpers", () => {
  jsdom();

  beforeEach(() => {
    window.decodeURIComponent = string => {
      return string.replace(/\%20/g, " ").replace(/\%26/g, "&");
    };
    window.encodeURIComponent = string => {
      return string.replace(/\s/g, "%20").replace(/\&/g, "%26");
    };
  });

  describe("parseParams", () => {
    it("turns an object into a query string", () => {
      expect(
        QueryStringHelpers.parseParams({ foo: "bar", bing: "bong" })
      ).to.equal("?foo=bar&bing=bong");
    });

    it("encodes characters", () => {
      expect(QueryStringHelpers.parseParams({ foo: "bar & baz" })).to.equal(
        "?foo=bar%20%26%20baz"
      );
    });

    it("returns an empty string if object has no values", () => {
      expect(QueryStringHelpers.parseParams({})).to.equal("");
    });
  });

  describe("parseQuery", () => {
    it("turns a query string into an object", () => {
      expect(QueryStringHelpers.parseQuery("?foo=bar&bing=bong")).to.deep.equal(
        { foo: "bar", bing: "bong" }
      );
    });

    it("decodes characters", () => {
      expect(
        QueryStringHelpers.parseQuery("?foo=bar%20%26%20baz+bat&bing=bong")
      ).to.deep.equal({ foo: "bar & baz bat", bing: "bong" });
    });

    it("returns an empty string if object has no values", () => {
      expect(QueryStringHelpers.parseQuery("")).to.deep.equal({});
    });
  });
});
