import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { AlgoliaResults } from '../../assets/js/algolia-results';

describe('AlgoliaResults', () => {
  jsdom();
  var search;

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="search-results"></div>
    `
    search = new AlgoliaResults("search-results");
  });

  describe('correct icon types are selected', () => {
    it("returns  span", () => {
      const hit = {_content_type: "search_result",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "<span");
      assert.include(search._contentIcon(hit), "</span>");
    });

    it("search_result", () => {
      const hit = {_content_type: "search_result",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-search");
    });

    it("news_entry", () => {
      const hit = {_content_type: "news_entry",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-newspaper-o");
    });

    it("event", () => {
      const hit = {_content_type: "event",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-calendar");
    });

    it("page", () => {
      const hit = {_content_type: "page",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-file-o");
    });

    it("landing_page", () => {
      const hit = {_content_type: "landing_page",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-file-o");
    });

    it("person", () => {
      const hit = {_content_type: "person",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-user");
    });

    it("other content typen", () => {
      const hit = {_content_type: "random_type",
                   _api_datasource: "entity:file"};
      assert.include(search._contentIcon(hit), "fa-file-o");
    });

    it("pdf", () => {
      const hit = {search_api_datasource: "entity:file",
                   _file_type: "application/pdf"};
      assert.include(search._contentIcon(hit), "fa-file-pdf-o");
    });

    it("excel", () => {
      const hit = {search_api_datasource: "entity:file",
                   _file_type: "application/vnd.ms-excel"};
      assert.include(search._contentIcon(hit), "fa-file-excel-o");
    });

    it("powerpoint", () => {
      const hit = {search_api_datasource: "entity:file",
                   _file_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation"};
      assert.include(search._contentIcon(hit), "fa-file-powerpoint-o");
    });

    it("other file type", () => {
      const hit = {search_api_datasource: "entity:file",
                   _file_type: "application/unrecognized"};
      assert.include(search._contentIcon(hit), "fa-file-o");
    });
  });

  describe('contentHitsFilter', () => {
    it('handles file types', () => {
      const hits = [{ search_api_datasource: "entity:file",
                      file_name_raw: "file-name",
                      _file_uri: "public://file-url"
                    }];

      const results = search._hitsFilter(hits, "drupal");

      assert.lengthOf(results, 1);
      assert.equal(results[0].hitTitle, "file-name");
      assert.equal(results[0].hitUrl, "/sites/default/files/file-url");
    });

    it('handles search_result', () => {
      const hits = [{ type: "search_result",
                      search_api_datasource: "no_file",
                      search_result_title: "title",
                      _search_result_url: "file-url"
                    }];

      const results = search._hitsFilter(hits, "drupal");

      assert.lengthOf(results, 1);
      assert.equal(results[0].hitTitle, "title");
      assert.equal(results[0].hitUrl, "file-url");
    });

    it('handles other result types', () => {
      const hits = [{ type: "other",
                      search_api_datasource: "no_file",
                      content_title: "title",
                      _content_url: "file-url"
                    }];

      const results = search._hitsFilter(hits, "drupal");

      assert.lengthOf(results, 1);
      assert.equal(results[0].hitTitle, "title");
      assert.equal(results[0].hitUrl, "file-url");
    });
  });

  describe('stopsHitsFilter', () => {
    var $;

    beforeEach(() => {
      $ = jsdom.rerequire('jquery');
      $('body').append(`
        <div id="icon-feature-stop">stop-icon</div>
      `);
    });

    it("properly maps icon, url and title", () => {
      const hits = [{stop: {
                       id: "stop-id",
                       name: "stop-name"
                     }
                    }];

      const result = search._hitsFilter(hits, "stops");

      assert.lengthOf(result, 1);
      assert.equal(result[0].hitUrl, "/stops/stop-id");
      assert.equal(result[0].hitTitle, "stop-name");
      assert.include(result[0].hitIcon, "stop");
    });
  });

  describe("_icon_from_route", () => {
    it("commuter_rail", () => {
      const route = {id: "CR-Fitchburg",
                     name: "Fitchburg Line",
                     type: 2
                    };

      assert.equal(search._iconFromRoute(route), "commuter_rail");
    });

    it("bus", () => {
      const route = {id: "93",
                     name: "93e",
                     type: 3
                    };

      assert.equal(search._iconFromRoute(route), "bus");
    });

    it("ferry", () => {
      const route = {id: "Boat-F4",
                     name: "Charlestown Ferry",
                     type: 4
                    };

      assert.equal(search._iconFromRoute(route), "ferry");
    });

    it("red line", () => {
      const route = {id: "Red",
                     name: "Red Line",
                     type: 1
                    };

      assert.equal(search._iconFromRoute(route), "red_line");
    });

    it("blue line", () => {
      const route = {id: "Blue",
                     name: "Blue Line",
                     type: 1
                    };

      assert.equal(search._iconFromRoute(route), "blue_line");
    });

    it("orange line", () => {
      const route = {id: "Orange",
                     name: "Orange Line",
                     type: 1
                    };

      assert.equal(search._iconFromRoute(route), "orange_line");
    });

    it("green line", () => {
      const route = {id: "Green",
                     name: "Green Line",
                     type: 0
                    };

      assert.equal(search._iconFromRoute(route), "green_line");
    });

    it("mattapan", () => {
      const route = {id: "Mattapan",
                     name: "Mattapan Trolley",
                     type: 0
                    };

      assert.equal(search._iconFromRoute(route), "mattapan_trolley");
    });
  });

  describe('routesHitsFilter', () => {
    var $;

    beforeEach(() => {
      $ = jsdom.rerequire('jquery');
      $('body').append(`
        <div id="icon-feature-commuter_rail">commuter-rail-icon</div>
        <div id="icon-feature-orange_line">orange-line-icon</div>
      `);
    });

    it("properly maps icon, url and title for commuter rail", () => {
      const hits = [{route: {
                       id: "CR-Fitchburg",
                       type: 2,
                       name: "Fitchburg Line"
                     }
                    }];

      const result = search._hitsFilter(hits, "routes");

      assert.lengthOf(result, 1);
      assert.equal(result[0].hitUrl, "/schedules/CR-Fitchburg/line");
      assert.equal(result[0].hitTitle, "Fitchburg Line");
      assert.include(result[0].hitIcon, "commuter-rail-icon");
    });

    it("properly maps icon, url and title for subway", () => {
      const hits = [{route: {
                       id: "Orange",
                       type: 1,
                       name: "Orange Line"
                     }
                    }];

      const result = search._hitsFilter(hits, "routes");

      assert.lengthOf(result, 1);
      assert.equal(result[0].hitUrl, "/schedules/Orange/line");
      assert.equal(result[0].hitTitle, "Orange Line");
      assert.include(result[0].hitIcon, "orange-line-icon");
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
                        drupal: {
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
                        drupal: {
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
                        drupal: {
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
                        drupal: {
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
