defmodule Site.RoutePdfsTest do
  use ExUnit.Case, async: true

  import Site.RoutePdfs

  alias Content.RoutePdf

  @date ~D[2018-01-01]

  describe "fetch_and_choose_pdfs/2" do
    test "returns at least one result" do
      assert [_at_least_one_result | _] = fetch_and_choose_pdfs("87", ~D[2019-01-01])
    end
  end

  describe "choose_pdfs/2" do
    test "handles zero pdfs" do
      assert choose_pdfs([], @date) == []
    end

    test "shows single basic pdf" do
      assert choose_pdfs([
        %RoutePdf{path: "/url", date_start: ~D[2017-12-01]},
      ], @date) == [
        %RoutePdf{path: "/url", date_start: ~D[2017-12-01]},
      ]
    end

    test "chooses most recent pdf if multiple are up-to-date" do
      assert choose_pdfs([
        %RoutePdf{path: "/url2", date_start: ~D[2017-12-01]},
        %RoutePdf{path: "/url1", date_start: ~D[2017-11-01]},
      ], @date) == [
        %RoutePdf{path: "/url2", date_start: ~D[2017-12-01]},
      ]
    end

    test "shows upcoming basic pdf" do
      assert choose_pdfs([
        %RoutePdf{path: "/url", date_start: ~D[2018-02-01]},
      ], @date) == [
        %RoutePdf{path: "/url", date_start: ~D[2018-02-01]},
      ]
    end

    test "shows upcoming basic pdf after current one" do
      assert choose_pdfs([
        %RoutePdf{path: "/url2", date_start: ~D[2018-02-01]},
        %RoutePdf{path: "/url1", date_start: ~D[2017-11-01]},
      ], @date) == [
        %RoutePdf{path: "/url1", date_start: ~D[2017-11-01]},
        %RoutePdf{path: "/url2", date_start: ~D[2018-02-01]},
      ]
    end

    test "shows most imminent upcoming pdf if there are multiple" do
      assert choose_pdfs([
        %RoutePdf{path: "/url2", date_start: ~D[2018-03-01]},
        %RoutePdf{path: "/url1", date_start: ~D[2018-02-01]},
      ], @date) == [
        %RoutePdf{path: "/url1", date_start: ~D[2018-02-01]},
      ]
    end

    test "considers pdfs that become effective today as current" do
      assert choose_pdfs([
        %RoutePdf{path: "/url", date_start: ~D[2018-01-01]},
      ], @date) == [
        %RoutePdf{path: "/url", date_start: ~D[2018-01-01]},
      ]
    end

    test "show single pdf with custom text" do
      assert choose_pdfs([
        %RoutePdf{path: "/url", date_start: ~D[2017-12-01], link_text_override: "Special Message"},
      ], @date) == [
        %RoutePdf{path: "/url", date_start: ~D[2017-12-01], link_text_override: "Special Message"},
      ]
    end

    test "shows multiple custom pdfs ordered by their input" do
      assert choose_pdfs([
        %RoutePdf{path: "/url1", date_start: ~D[2017-12-01], link_text_override: "Special Message 1"},
        %RoutePdf{path: "/url2", date_start: ~D[2017-11-01], link_text_override: "Special Message 2"},
      ], @date) == [
        %RoutePdf{path: "/url1", date_start: ~D[2017-12-01], link_text_override: "Special Message 1"},
        %RoutePdf{path: "/url2", date_start: ~D[2017-11-01], link_text_override: "Special Message 2"},
      ]
    end

    test "does not show upcoming pdf with custom text" do
      assert choose_pdfs([
        %RoutePdf{path: "/url", date_start: ~D[2018-02-01], link_text_override: "Special Message"},
      ], @date) == []
    end

    test "considers pdfs with custom text that become effective today as current" do
      assert choose_pdfs([
        %RoutePdf{path: "/url", date_start: ~D[2018-01-01], link_text_override: "Special Message"},
      ], @date) == [
        %RoutePdf{path: "/url", date_start: ~D[2018-01-01], link_text_override: "Special Message"},
      ]
    end

    test "orders results basic-current, basic-upcoming, custom-text" do
      assert choose_pdfs([
        %RoutePdf{path: "/upcoming", date_start: ~D[2018-02-01]},
        %RoutePdf{path: "/custom1", date_start: ~D[2017-12-01], link_text_override: "Special Message 1"},
        %RoutePdf{path: "/basic", date_start: ~D[2017-11-01]},
        %RoutePdf{path: "/custom2", date_start: ~D[2017-10-01], link_text_override: "Special Message 2"},
      ], @date) == [
        %RoutePdf{path: "/basic", date_start: ~D[2017-11-01]},
        %RoutePdf{path: "/upcoming", date_start: ~D[2018-02-01]},
        %RoutePdf{path: "/custom1", date_start: ~D[2017-12-01], link_text_override: "Special Message 1"},
        %RoutePdf{path: "/custom2", date_start: ~D[2017-10-01], link_text_override: "Special Message 2"},
      ]
    end

    test "does not show expired pdfs" do
      assert choose_pdfs([
        %RoutePdf{path: "/expired-basic", date_start: ~D[2017-11-01], date_end: ~D[2017-11-02]},
        %RoutePdf{path: "/expired-custom", date_start: ~D[2017-12-01], date_end: ~D[2017-12-02], link_text_override: "Special Message 1"},
        %RoutePdf{path: "/current-custom", date_start: ~D[2017-10-01], link_text_override: "Special Message 2"},
      ], @date) == [
        %RoutePdf{path: "/current-custom", date_start: ~D[2017-10-01], link_text_override: "Special Message 2"},
      ]
    end

    test "shows not-yet-expired pdfs" do
      assert choose_pdfs([
        %RoutePdf{path: "/basic", date_start: ~D[2017-11-01], date_end: ~D[2018-01-02]},
        %RoutePdf{path: "/custom", date_start: ~D[2017-12-01], date_end: ~D[2018-01-02], link_text_override: "x"},
      ], @date) == [
        %RoutePdf{path: "/basic", date_start: ~D[2017-11-01], date_end: ~D[2018-01-02]},
        %RoutePdf{path: "/custom", date_start: ~D[2017-12-01], date_end: ~D[2018-01-02], link_text_override: "x"},
      ]
    end

    test "considers expiring today as still being current" do
      assert choose_pdfs([
        %RoutePdf{path: "/basic", date_start: ~D[2017-11-01], date_end: ~D[2018-01-01]},
        %RoutePdf{path: "/custom", date_start: ~D[2017-12-01], date_end: ~D[2018-01-01], link_text_override: "x"},
      ], @date) == [
        %RoutePdf{path: "/basic", date_start: ~D[2017-11-01], date_end: ~D[2018-01-01]},
        %RoutePdf{path: "/custom", date_start: ~D[2017-12-01], date_end: ~D[2018-01-01], link_text_override: "x"},
      ]
    end

    test "comprehensive test" do
      assert choose_pdfs([
        %RoutePdf{path: "/custom-expired", date_start: ~D[2017-07-01], date_end: ~D[2017-08-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-current", date_start: ~D[2017-08-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-current-expires", date_start: ~D[2017-09-01], date_end: ~D[2018-05-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-starts-today", date_start: ~D[2018-01-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-ends-today", date_start: ~D[2017-09-01], date_end: ~D[2018-01-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-one-day-only", date_start: ~D[2018-01-01], date_end: ~D[2018-01-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-future-expires", date_start: ~D[2018-04-01], date_end: ~D[2018-05-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-future", date_start: ~D[2018-03-01], link_text_override: "x"},
        %RoutePdf{path: "/basic-expired", date_start: ~D[2017-10-01], date_end: ~D[2017-11-02]},
        %RoutePdf{path: "/basic-current-old", date_start: ~D[2017-11-01]},
        %RoutePdf{path: "/basic-current-new-expires", date_start: ~D[2017-12-01], date_end: ~D[2018-02-01]},
        %RoutePdf{path: "/basic-upcoming", date_start: ~D[2018-03-01]},
        %RoutePdf{path: "/basic-upcoming-expires", date_start: ~D[2017-04-01], date_end: ~D[2018-05-01]},
      ], @date) == [
        %RoutePdf{path: "/basic-current-new-expires", date_start: ~D[2017-12-01], date_end: ~D[2018-02-01]},
        %RoutePdf{path: "/basic-upcoming", date_start: ~D[2018-03-01]},
        %RoutePdf{path: "/custom-current", date_start: ~D[2017-08-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-current-expires", date_start: ~D[2017-09-01], date_end: ~D[2018-05-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-starts-today", date_start: ~D[2018-01-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-ends-today", date_start: ~D[2017-09-01], date_end: ~D[2018-01-01], link_text_override: "x"},
        %RoutePdf{path: "/custom-one-day-only", date_start: ~D[2018-01-01], date_end: ~D[2018-01-01], link_text_override: "x"},
      ]
    end
  end
end
