defmodule GlobalSearchTest do
  use SiteWeb.IntegrationCase, async: true
  import Wallaby.Query

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

  def search_results_section(count) do
    css(".c-search-results__section", count: count)
  end

  def search_hits(count) do
    css(".c-search-result__hit", count: count)
  end

  def toggle_facet_section(session, name) do
    click(session, css("#expansion-container-#{name}"))

  end

  def click_facet_checkbox(session, facet) do
    click(session, css("#checkbox-container-#{facet}"))
  end

  def click_clear_search(session) do
    click(session, css("#search-clear-icon"))
  end
end
