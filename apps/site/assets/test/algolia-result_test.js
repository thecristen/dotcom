import jsdom from "mocha-jsdom";
import { expect, assert } from "chai";
import * as AlgoliaResult from "../../assets/js/algolia-result";

describe("AlgoliaResult", () => {
  jsdom();
  before(() => {
    document.body.innerHTML = `
      <div id="icon-feature-commuter_rail"><span>commuter rail icon</span></div>
      <div id="icon-feature-bus"><span>bus icon</span></div>
      <div id="icon-feature-ferry"><span>ferry icon</span></div>
      <div id="icon-feature-red_line"><span>red line icon</span></div>
      <div id="icon-feature-blue_line"><span>blue line icon</span></div>
      <div id="icon-feature-orange_line"><span>orange line icon</span></div>
      <div id="icon-feature-green_line"><span>green line icon</span></div>
      <div id="icon-feature-mattapan_trolley"><span>mattapan line icon</span></div>
    `;
  });
  describe("getIcon", () => {
    describe('renders correct icon for Drupal results', () => {
      it("returns  span", () => {
        const hit = {
          _content_type: "search_result",
          _api_datasource: "entity:file"
        };
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "<span");
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "</span>");
      });

      it("search_result", () => {
        const hit = {_content_type: "search_result",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-search");
      });

      it("news_entry", () => {
        const hit = {_content_type: "news_entry",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-newspaper-o");
      });

      it("event", () => {
        const hit = {_content_type: "event",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-calendar");
      });

      it("page", () => {
        const hit = {_content_type: "page",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-o");
      });

      it("landing_page", () => {
        const hit = {_content_type: "landing_page",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-o");
      });

      it("person", () => {
        const hit = {_content_type: "person",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-user");
      });

      it("other content typen", () => {
        const hit = {_content_type: "random_type",
                    _api_datasource: "entity:file"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-o");
      });

      it("pdf", () => {
        const hit = {search_api_datasource: "entity:file",
                    _file_type: "application/pdf"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-pdf-o");
      });

      it("excel", () => {
        const hit = {search_api_datasource: "entity:file",
                    _file_type: "application/vnd.ms-excel"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-excel-o");
      });

      it("powerpoint", () => {
        const hit = {search_api_datasource: "entity:file",
                    _file_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-powerpoint-o");
      });

      it("other file type", () => {
        const hit = {search_api_datasource: "entity:file",
                    _file_type: "application/unrecognized"};
        assert.include(AlgoliaResult.getIcon(hit, "drupal"), "fa-file-o");
      });
    });
    describe("renders correct icon for route type", () => {
      it("commuter_rail", () => {
        const hit = {
          route: {
            id: "CR-Fitchburg",
            name: "Fitchburg Line",
            type: 2
          }
        }

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>commuter rail icon</span>");
      });

      it("bus", () => {
        const hit = {
          route: {
            id: "93",
            name: "93e",
            type: 3
          }
        };

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>bus icon</span>");
      });

      it("ferry", () => {
        const hit = {
          route: {
            id: "Boat-F4",
            name: "Charlestown Ferry",
            type: 4
          }
        };

        assert.equal(AlgoliaResult.getIcon(hit, "routes"), "<span>ferry icon</span>");
      });

      it("red line", () => {
        const hit = {
          route: {
            id: "Red",
            name: "Red Line",
            type: 1
          }
        };

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>red line icon</span>");
      });

      it("blue line", () => {
        const hit = {
          route: {
            id: "Blue",
            name: "Blue Line",
            type: 1
          }
        };

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>blue line icon</span>");
      });

      it("orange line", () => {
        const hit = {
          route: {
            id: "Orange",
            name: "Orange Line",
            type: 1
          }
        };

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>orange line icon</span>");
      });

      it("green line", () => {
        const hit = {
          route: {
            id: "Green-C",
            name: "Green Line C Branch",
            type: 0
          }
        };

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>green line icon</span>");
      });

      it("mattapan line", () => {
        const hit = {
          route: {
            id: "Mattapan",
            name: "Mattapan Trolley",
            type: 0
          }
        };

        expect(AlgoliaResult.getIcon(hit, "routes")).to.equal("<span>mattapan line icon</span>");
      });
    });
  });
});
