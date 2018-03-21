import { assert, expect } from 'chai';
import jsdom from 'mocha-jsdom';
import { AlgoliaResults } from '../../assets/js/algolia-results';

describe('AlgoliaResults', () => {
  jsdom();
  var search;

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="icon-feature-stop">stop-icon</div>
      <div id="icon-feature-commuter_rail">commuter-rail-icon</div>
      <div id="icon-feature-orange_line">orange-line-icon</div>
      <div id="search-results"></div>
    `
    search = new AlgoliaResults("search-results");
  });

  describe('renderIndex', () => {
    describe("for drupal results", () => {
      it('handles file types', () => {
        const hit = {
          search_api_datasource: "entity:file",
          file_name_raw: "file-file-name",
          _file_uri: "public://file-url"
        }

        const results = search._renderIndex({
          drupal: {
            nbHits: 1,
            hits: [hit]
          }
        }, "drupal");

        expect(results).to.be.a("string");
        expect(results).to.have.string(hit.file_name_raw);
        expect(results).to.have.string("/sites/default/files/file-url");
      });

      it('handles search_result', () => {
        const hit = { _content_type: "search_result",
                      search_api_datasource: "no_file",
                      content_title: "search-results-title",
                      _search_result_url: "file-url"
                    };
        const results = search._renderIndex({
          drupal: {
            nbHits: 1,
            hits: [hit]
          }
        }, "drupal");

        expect(results).to.be.a("string");
        expect(results).to.have.string(hit.content_title);
        expect(results).to.have.string(hit._search_result_url);
      });

      it('handles other result types', () => {
        const hit = { _content_type: "other",
                        search_api_datasource: "no_file",
                        content_title: "content-title",
                        _content_url: "file-url"
                      };

        const results = search._renderIndex({
          drupal: {
            nbHits: 1,
            hits: [hit]
          }
        }, "drupal");

        expect(results).to.be.a("string");
        expect(results).to.have.string(hit.content_title);
        expect(results).to.have.string(hit._content_url);
      });
    });
    describe("for stop results", () => {
      it("properly maps icon, url and title", () => {
        const hit = {
          stop: {
            id: "stop-id",
            name: "stop-name"
          }
        };

        const result = search._renderIndex({
          stops: {
            nbHits: 1,
            hits: [hit]
          }
        }, "stops");

        expect(result).to.be.a("string");
        expect(result).to.have.string("/stops/" + hit.stop.id);
        expect(result).to.have.string(hit.stop.name);
        expect(result).to.have.string("stop-icon");
      });
    });
    describe("for route results", () => {
      it("properly maps icon, url and title for commuter rail", () => {
        const hit = {
          route: {
           id: "CR-Fitchburg",
           type: 2,
           name: "Fitchburg Line"
          }
        };

        const result = search._renderIndex({
          routes: {
            nbHits: 1,
            hits: [hit]
          }
        }, "routes");

        expect(result).to.be.a("string");
        expect(result).to.have.string("/schedules/" + hit.route.id);
        expect(result).to.have.string(hit.route.name);
        expect(result).to.have.string("commuter-rail-icon");
      });

      it("properly maps icon, url and title for subway", () => {
        const hit = {
          route: {
            id: "Orange",
            type: 1,
            name: "Orange Line"
          }
        };

        const result = search._renderIndex({
          routes: {
            nbHits: 1,
            hits: [hit]
          }
        }, "routes");

        expect(result).to.be.a("string");
        expect(result).to.have.string("/schedules/" + hit.route.id);
        expect(result).to.have.string(hit.route.name);
        expect(result).to.have.string("orange-line-icon");
      });
    });
  });

  describe('routesHitsFilter', () => {
    var $;

    beforeEach(() => {
      $ = jsdom.rerequire('jquery');
      $('body').append(`
      `);
    });

  });

  describe("render", () => {
    var $;

    beforeEach(() => {
      $ = jsdom.rerequire('jquery');
      $('body').append(`
        <div id="icon-feature-bus">bus-icon</div>
        <div id="icon-feature-stop">stop-icon</div>
        <div id="search-results"></div>
      `);
    });

    it("renders empty HTML when no hits", () => {
      const results = {
                        stops: {
                          hits: []
                        },
                        routes: {
                          hits: []
                        },
                        pagesdocuments: {
                          hits: []
                        }
                      };
      search.render(results);

      const sections = document.getElementsByClassName('c-search-results__section');
      const hits = document.getElementsByClassName('c-search-result__hit');
      assert.lengthOf(sections, 3);
      assert.lengthOf(hits, 0);
    });

    it("renders stops hits", () => {
      const results = {
                        stops: {
                          title: "title",
                          nbHits: 2,
                          hasHits: true,
                          hits: [ { hitUrl: "url1",
                                    hitIcon: "icon1",
                                    hitTitle: "title1",
                                    stop: {
                                      id: "id1",
                                      name: "name1"
                                    }
                                  },
                                  { hitUrl: "url2",
                                    hitIcon: "icon2",
                                    hitTitle: "title2",
                                    stop: {
                                      id: "id2",
                                      name: "name2"
                                    }
                                  },
                                ]
                        },
                        routes: {
                          hits: []
                        },
                        pagesdocuments: {
                          hits: []
                        }
                      };
      search.render(results);

      const sections = document.getElementsByClassName('c-search-results__section');
      const hits = document.getElementsByClassName('c-search-result__hit');
      assert.lengthOf(sections, 3);
      assert.lengthOf(hits, 2);
    });

    it("renders routes hits", () => {
      const results = {
                        routes: {
                          title: "title",
                          nbHits: 2,
                          hasHits: true,
                          hits: [ { hitUrl: "url1",
                                    hitIcon: "icon1",
                                    hitTitle: "title1",
                                    route: {
                                      type: 3,
                                      id: "id1",
                                      name: "name1"
                                    }
                                  },
                                  { hitUrl: "url2",
                                    hitIcon: "icon2",
                                    hitTitle: "title2",
                                    route: {
                                      type: 3,
                                      id: "id2",
                                      name: "name2"
                                    }
                                  },
                                ]
                        },
                        stops: {
                          hits: []
                        },
                        pagesdocuments: {
                          hits: []
                        }
                      };
      search.render(results);

      const sections = document.getElementsByClassName('c-search-results__section');
      const hits = document.getElementsByClassName('c-search-result__hit');
      assert.lengthOf(sections, 3);
      assert.lengthOf(hits, 2);
    });

    it("renders content hits", () => {
      const results = {
                        pagesdocuments: {
                          title: "title",
                          nbHits: 2,
                          hasHits: true,
                          hits: [ { hitUrl: "url1",
                                    hitIcon: "icon1",
                                    hitTitle: "title1",
                                  },
                                  { hitUrl: "url2",
                                    hitIcon: "icon2",
                                    hitTitle: "title2",
                                  },
                                ]
                        },
                        stops: {
                          hits: []
                        },
                        routes: {
                          hits: []
                        }
                      };
      search.render(results);

      const sections = document.getElementsByClassName('c-search-results__section');
      const hits = document.getElementsByClassName('c-search-result__hit');
      assert.lengthOf(sections, 3);
      assert.lengthOf(hits, 2);
    });
  });
});
