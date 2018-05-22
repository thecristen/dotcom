defmodule SiteWeb.GlobalSearchTest do
  use SiteWeb.IntegrationCase, async: true
  import Wallaby.Query
  import SiteWeb.IntegrationHelpers

  @search_input css("#search-input")

  describe "basic search" do
    @tag :wallaby
    test "can perform a search", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
    end
  end

  describe "facets" do
    @tag :wallaby
    test "selecting a facet limits results sections", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
      |> click_facet_checkbox("locations")
      |> assert_has(search_results_section(1))
    end

    @tag :wallaby
    test "selecting and unselecting a facet returns all results", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
      |> click_facet_checkbox("locations")
      |> assert_has(search_results_section(1))
      |> click_facet_checkbox("locations")
      |> assert_has(search_results_section(6))
    end

    @tag :wallaby
    test "lines and routes facets can be expanded and checked", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Green")
      |> assert_has(search_results_section(6))

      # With all lines and routes selected we should see Greenbush and 4 Green line branches
      |> click_facet_checkbox("lines-routes")
      |> assert_has(search_results_section(1))
      |> assert_has(search_hits(5))
      |> assert_has(Query.text("bush Line"))
      |> assert_has(Query.text("Line B"))
      |> assert_has(Query.text("Line C"))
      |> assert_has(Query.text("Line D"))
      |> assert_has(Query.text("Line E"))

      # Disable bus, commuter rail and ferry and we should see only 4 green line branches
      |> toggle_facet_section("lines-routes")
      |> click_facet_checkbox("bus")
      |> click_facet_checkbox("commuter-rail")
      |> click_facet_checkbox("ferry")
      |> assert_has(search_results_section(1))
      |> assert_has(search_hits(4))
      |> assert_has(Query.text("Line B"))
      |> assert_has(Query.text("Line C"))
      |> assert_has(Query.text("Line D"))
      |> assert_has(Query.text("Line E"))
    end

    @tag :wallaby
    test "stations and stops facets can be expanded", %{session: session} do
      session
      |> visit("/search")
      |> assert_has(css("#checkbox-container-facet-station", visible: false))
      |> assert_has(css("#checkbox-container-facet-stop", visible: false))
      |> toggle_facet_section("stops")
      |> assert_has(css("#checkbox-container-facet-station"))
      |> assert_has(css("#checkbox-container-facet-stop"))
    end

    @tag :wallaby
    test "pages and documents facets can be expanded", %{session: session} do
      session
      |> visit("/search")
      |> assert_has(css("#checkbox-container-page", visible: false))
      |> assert_has(css("#checkbox-container-document", visible: false))
      |> toggle_facet_section("pages-parent")
      |> assert_has(css("#checkbox-container-page"))
      |> assert_has(css("#checkbox-container-document"))
    end

    @tag :wallaby
    test "clearing all facets results in a full search", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))

      # Select some facets within lines and routes
      |> toggle_facet_section("lines-routes")
      |> click_facet_checkbox("bus")
      |> click_facet_checkbox("commuter-rail")
      |> click_facet_checkbox("ferry")
      |> assert_has(search_results_section(1))

      # Unslelect all selected facets and ensure we are back to a full search
      |> click_facet_checkbox("bus")
      |> click_facet_checkbox("commuter-rail")
      |> click_facet_checkbox("ferry")
      |> assert_has(search_results_section(6))
    end

    @tag :wallaby
    test "show more link works", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "a")
      |> assert_has(search_results_section(6))
      |> click_facet_checkbox("stops")
      |> assert_has(search_results_section(1))
      |> assert_has(search_hits(5))
      |> click(css("#show-more--stops"))
      |> assert_has(search_hits(25))
    end
  end

  describe "reset search" do
    @tag :wallaby
    test "search results clear button clears search", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
      |> click_clear_search()
      |> assert_has(search_results_section(0))
    end

    @tag :wallaby
    test "search results clear button clears all facet checkboxes", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
      |> click_facet_checkbox("event")
      |> click_facet_checkbox("locations")
      |> assert_has(search_results_section(2))
      |> assert_has(css(".c-facets__checkbox--checked", count: 2))
      |> click_clear_search()
      |> assert_has(css(".c-facets__checkbox--checked", count: 0))
    end

    @tag :wallaby
    test "clearing search resets show more", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "a")
      |> assert_has(search_results_section(6))
      |> click_facet_checkbox("stops")
      |> assert_has(search_results_section(1))
      |> assert_has(search_hits(5))
      |> click(css("#show-more--stops"))
      |> assert_has(search_hits(25))
      |> click_clear_search()
      |> fill_in(@search_input, with: "a")
      |> click_facet_checkbox("stops")
      |> assert_has(search_hits(5))
    end

    @tag :wallaby
    test "search results clear when search field cleared", %{session: session} do
      session
      |> visit("/search")
      |> fill_in(@search_input, with: "aa")
      |> assert_has(search_results_section(6))
      |> send_keys([:backspace])
      |> assert_has(search_results_section(6))
      |> send_keys([:backspace])
      |> assert_has(search_results_section(0))
    end
  end

  describe "mobile search" do
    @tag :wallaby
    test "can perform basic search", %{session: session} do
      session
      |> resize_window(320, 480)
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
    end

    @tag :wallaby
    test "can perform facet filter", %{session: session} do
      session
      |> resize_window(320, 480)
      |> visit("/search")
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(search_results_section(6))
      |> click(css("#show-facets"))
      |> click_facet_checkbox("locations")
      |> assert_has(search_results_section(1))
    end
  end

  describe "load state" do
    @tag :wallaby
    test "fills in query", %{session: session} do
      session = visit(session, "/search?query=Test")
      assert attr(session, @search_input, "value") == "Test"
    end

    @tag :wallaby
    test "checks off facets and does a search", %{session: session} do
      session = visit(session, "/search?query=alewife&facets=stops,facet-station,facet-stop")
      assert attr(session, @search_input, "value") == "alewife"
      session = session
      |> assert_has(search_results_section(1))
      |> assert_has(search_hits(1))
      assert selected?(session, facet_checkbox("stops"))
      assert selected?(session, facet_checkbox("facet-station"))
      assert selected?(session, facet_checkbox("facet-stop"))
    end

    @tag :wallaby
    test "does a search, checks off facets and loads show more", %{session: session} do
      session = visit(session, "/search?query=alewife&facets=pages-parent,page,document&showmore=pagesdocuments")
      assert attr(session, @search_input, "value") == "alewife"
      session = session
      |> assert_has(search_results_section(1))
      |> assert_has(search_hits(7))
      assert selected?(session, facet_checkbox("pages-parent"))
      assert selected?(session, facet_checkbox("page"))
      assert selected?(session, facet_checkbox("document"))
    end
  end
end
