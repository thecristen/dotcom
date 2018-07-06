defmodule SiteWeb.HomepageSearchTest do
  use SiteWeb.IntegrationCase
  alias Wallaby.Browser
  import Wallaby.Query
  import SiteWeb.IntegrationHelpers

  @search_input css("#homepage-search__input")

  setup tags do
    %{session: %Wallaby.Session{} = session} = Map.new(tags)
    {:ok, session: visit(session, "/")}
  end

  describe "basic search" do
    @tag :wallaby
    test "clicking show more goes to search page with facet checked and show more populated", %{session: session} do
      session =
        session
        |> fill_in(@search_input, with: "Alewife")
        |> assert_has(css(".c-search-bar__-dataset-pagesdocuments"))
        |> click(css("#show-more--pagesdocuments"))

      assert Wallaby.Browser.text(session, css(".c-search-result__header")) == "Pages and Documents"
      section = find(session, search_results_section(1))
      assert_has(section, search_hits(7))
      assert selected?(session, facet_checkbox("pages-parent"))
      assert selected?(session, facet_checkbox("page"))
      assert selected?(session, facet_checkbox("document"))
    end
  end

  describe "reset button" do
    @tag :wallaby
    test "resets search", %{session: session} do
      result_selector = ".c-search-bar__-dataset-stops .c-search-bar__-suggestion"
      result = css(result_selector)
      reset_btn = css("#homepage-search__reset")

      session =
        session
        |> fill_in(@search_input, with: "alewife")
        |> assert_has(result)

      assert Browser.text(session, result) == "Alewife"

      session = click(session, reset_btn)

      assert attr(session, @search_input, "value") == ""

      session = fill_in(session, @search_input, with: "green")

      assert [first, _] = find(session, css(result_selector, count: 2))
      assert Element.text(first) =~ "Greenwood"
    end

    @tag :wallaby
    test "only shown when input has a value", %{session: session} do
      reset_id = "#homepage-search__reset"
      session
      |> assert_has(css(reset_id, visible: false))
      |> fill_in(@search_input, with: "a")
      |> assert_has(css(reset_id, visible: true))
      |> send_keys(@search_input, [:backspace])
      |> assert_has(css(reset_id, visible: false))
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
      |> visit("/")
      |> assert_has(css("#algolia-error", visible: false))
      |> fill_in(@search_input, with: "a")
      |> assert_has(css("#algolia-error", visible: true))
    end
  end

  @tag :wallaby
  test "tracks clicks", %{session: session} do
    bypass = Bypass.open()

    old_url = Application.get_env(:algolia, :click_analytics_url)
    Application.put_env(:algolia, :track_clicks?, true)
    Application.put_env(:algolia, :click_analytics_url, "http://localhost:#{bypass.port}")

    parent = self()

    Bypass.expect(bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      case Poison.decode(body) do
        {:ok, %{"objectID" => "stop-place-" <> _, "queryID" => <<_::binary>>, "position" => 1}} ->
          send parent, :click_tracked
        decoded ->
          send parent, {:bad_click_request, decoded}
          :ok
      end
      Plug.Conn.send_resp(conn, 200, "{}")
    end)

    on_exit fn ->
      Application.put_env(:algolia, :track_clicks?, false)
      Application.put_env(:algolia, :click_analytics_url, old_url)
    end

    session =
      session
      |> fill_in(@search_input, with: "Alewife")
      |> assert_has(css(".c-search-bar__-dataset-stops"))

    click(session, Wallaby.Query.link("Alewife"))

    assert_receive :click_tracked
  end
end
