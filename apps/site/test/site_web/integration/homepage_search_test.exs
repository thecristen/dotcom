defmodule HomepageSearchTest do
  use SiteWeb.IntegrationCase, async: true
  import Wallaby.Query

  @search_input css("#homepage-search__input")

  describe "basic search" do
    @tag :wallaby
    test "can click show more and go to search page with facet checked", %{session: session} do
      session =
        session
        |> visit("/")
        |> fill_in(@search_input, with: "Alewife")
        |> assert_has(css(".c-search-bar__-dataset-stops"))
        |> click(css("#show-more--stops"))
        |> assert_has(css("#facet-label-stops"))
      assert attr(session, css("#checkbox-item-stops", visible: false), "checked") == "true"
    end
  end
end
