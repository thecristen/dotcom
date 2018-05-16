defmodule SiteWeb.HomepageSearchTest do
  use SiteWeb.IntegrationCase, async: true
  alias Wallaby.Browser
  import Wallaby.Query

  @search_input css("#homepage-search__input")

  setup tags do
    %{session: %Wallaby.Session{} = session} = Map.new(tags)
    {:ok, session: visit(session, "/")}
  end

  describe "basic search" do
    @tag :wallaby
    test "can click show more and go to search page with facet checked", %{session: session} do
      session =
        session
        |> fill_in(@search_input, with: "Alewife")
        |> assert_has(css(".c-search-bar__-dataset-stops"))
        |> click(css("#show-more--stops"))
        |> assert_has(css("#facet-label-stops"))
      assert attr(session, css("#checkbox-item-stops", visible: false), "checked") == "true"
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
end
