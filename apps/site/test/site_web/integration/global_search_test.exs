defmodule SiteWeb.GlobalSearchTest do
  use SiteWeb.IntegrationCase
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
      |> assert_has(search_results_section(6))
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

    @tag :wallaby
    test "clear button only shows when text has been entered", %{session: session} do
      reset_id = "#search-clear-icon"
      session
      |> visit("/search")
      |> assert_has(css(reset_id, visible: false))
      |> fill_in(@search_input, with: "a")
      |> assert_has(css(reset_id, visible: true))
      |> send_keys(@search_input, [:backspace])
      |> assert_has(css(reset_id, visible: false))
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

  describe "url parameters" do
    @tag :wallaby
    test "url parameters change when search field is filled", %{session: session} do
      url =
        session
        |> visit("/search")
        |> fill_in(@search_input, with: "Alewife")
        |> current_url()

      query_string_elements = url_to_param_map(url)

      assert Keyword.fetch(query_string_elements, :query) == {:ok, "Alewife"}
      assert Keyword.fetch(query_string_elements, :facets) == {:ok, ""}
      assert Keyword.fetch(query_string_elements, :showmore) == {:ok, ""}
    end

    @tag :wallaby
    test "selected facets are tracked in url params", %{session: session} do
      url =
        session
        |> visit("/search")
        |> click_facet_checkbox("stops")
        |> current_url()

      query_string_elements = url_to_param_map(url)

      assert Keyword.fetch(query_string_elements, :query) == {:ok, ""}
      assert Keyword.fetch(query_string_elements, :facets) == {:ok, "stops,facet-station,facet-stop"}
      assert Keyword.fetch(query_string_elements, :showmore) == {:ok, ""}
    end

    @tag :wallaby
    test "show more is tracked in url params", %{session: session} do
      url =
        session
        |> visit("/search")
        |> fill_in(@search_input, with: "a")
        |> click(css("#show-more--stops"))
        |> current_url()

      query_string_elements = url_to_param_map(url)

      assert Keyword.fetch(query_string_elements, :query) == {:ok, "a"}
      assert Keyword.fetch(query_string_elements, :facets) == {:ok, ""}
      assert Keyword.fetch(query_string_elements, :showmore) == {:ok, "stops"}
    end
  end

  describe "url parameters on followed links" do
    setup do
      bypass = Bypass.open()
      old_url = Application.get_env(:algolia, :click_analytics_url)
      Application.put_env(:algolia, :click_analytics_url, "http://localhost:#{bypass.port}")

      on_exit fn ->
        Application.put_env(:algolia, :click_analytics_url, old_url)
      end

      {:ok, bypass: bypass}
    end

    @tag :wallaby
    test "location url contains correct query params", %{session: session, bypass: bypass} do
      Bypass.expect(bypass, fn conn -> Plug.Conn.send_resp(conn, 200, "success") end)
      session =
        session
        |> visit("/search")
        |> fill_in(@search_input, with: "community college")
        |> click_facet_checkbox("stops")
        |> assert_has(search_results_section(:any))
        |> assert_has(css(".c-search-result__link", count: :any))

      [first_link | _]  = find(session, css(".c-search-result__link", count: :any))

      Wallaby.Element.click(first_link)
      assert_has(session, css(".stations-address"))

      url = current_url(session)

      parsed_url = URI.parse(url)
      assert parsed_url.path == "/stops/place-ccmnl"

      query_string_elements = url_to_param_map(url)
      assert Keyword.fetch(query_string_elements, :from) == {:ok, "global-search"}
      assert Keyword.fetch(query_string_elements, :query) == {:ok, "community college"}
      assert Keyword.fetch(query_string_elements, :facets) == {:ok, "stops,facet-station,facet-stop"}
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

  describe "bad response" do
    @tag :wallaby
    @tag :capture_log
    test "displays an error message", %{session: session} do
      config = Application.get_env(:algolia, :config)
      bad_config = Keyword.delete(config, :admin)
      Application.put_env(:algolia, :config, bad_config)
      on_exit(fn -> Application.put_env(:algolia, :config, config) end)

      session
      |> visit("/search")
      |> assert_has(css("#algolia-error", visible: false))
      |> fill_in(@search_input, with: "a")
      |> assert_has(css("#algolia-error", visible: true))
    end
  end

  def url_to_param_map(url) do
    query_string = URI.parse(url)

    query_string.query
      |> URI.query_decoder()
      |> Enum.map(fn({a, b}) -> {String.to_atom(a), b} end)
  end
end
