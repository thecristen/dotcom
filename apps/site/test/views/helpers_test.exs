defmodule Site.ViewHelpersTest do
  @moduledoc false
  use Site.ConnCase, async: true

  import Site.ViewHelpers
  import Phoenix.HTML.Tag, only: [content_tag: 3, tag: 2]
  alias Routes.Route

  describe "route_header_text/2" do
    test "translates the type number to a string" do
      assert route_header_text(%Route{type: 0, name: "test route"}) == "test route"
      assert route_header_text(%Route{type: 3, name: "2"}) == ["Route ", "2"]
      assert route_header_text(%Route{type: 1, name: "Red Line"}) == "Red Line"
      assert route_header_text(%Route{type: 2, name: "Fitchburg Line"}) == "Fitchburg"
    end
  end

  describe "hidden_query_params/2" do
    test "creates a hidden tag for each query parameter", %{conn: conn} do
      actual = hidden_query_params(%{conn | query_params: %{"one" => "value", "two" => "other"}})

      expected = [tag(:input, type: "hidden", name: "one", value: "value"),
                  tag(:input, type: "hidden", name: "two", value: "other")]

      assert expected == actual
    end
  end

  describe "update_query/2" do
    test "maintains existing parameters while updating passed params" do
      assert update_query(%{params: %{"param1" => "one", "param2" => "two"}}, %{param2: "2"}) == %{"param1" => "one", "param2" => "2"}
    end

    test "when given no new parameters, does not change its input" do
      params = %{"param1" => "one", "param2" => "two"}
      assert update_query(%{params: params}, []) == params
    end
  end

  describe "update_url/2" do
    test "doesn't include a ? when there aren't any query strings" do
      conn = build_conn(:get, "/path")
      conn = fetch_query_params(conn, [])
      assert update_url(conn, []) == "/path"
    end

    test "includes params when they're updated" do
      conn = build_conn(:get, "/path")
      conn = fetch_query_params(conn, [])
      assert update_url(conn, param: "eter") == "/path?param=eter"
    end
  end

  describe "station_link/1" do
    test "given a station, returns a link to that station" do
      link = %Stations.Station{id: "place-sstat", name: "South Station"}
      |> station_link
      |> Phoenix.HTML.safe_to_string
      assert link == ~s(<a href="/stations/place-sstat">South Station</a>)
    end

    test "given a station ID, returns a link to that station" do
      link = "place-sstat"
      |> station_link
      |> Phoenix.HTML.safe_to_string
      assert link == ~s(<a href="/stations/place-sstat">South Station</a>)
    end
  end

  describe "mode_icon/1" do
    test "correctly finds the icon for the ride" do
      expected = content_tag :span, class: "route-icon route-icon-the-ride" do
        svg("the-ride.svg")
      end
      assert mode_icon(:the_ride) == expected
    end
  end
end
