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

  describe "stop_link/1" do
    test "given a stop, returns a link to that stop" do
      link = %Stops.Stop{id: "place-sstat", name: "South Station"}
      |> stop_link
      |> Phoenix.HTML.safe_to_string
      assert link == ~s(<a href="/stops/place-sstat">South Station</a>)
    end

    test "given a stop ID, returns a link to that stop" do
      link = "place-sstat"
      |> stop_link
      |> Phoenix.HTML.safe_to_string
      assert link == ~s(<a href="/stops/place-sstat">South Station</a>)
    end
  end

  describe "mode_icon/1" do
    test "correctly finds the icon for the ride" do
      expected = content_tag :span, title: "The Ride", class: "route-icon route-icon-the-ride" do
        svg("the-ride.svg")
      end
      assert mode_icon(:the_ride) == expected
    end

    test "correctly finds the icon for commuter rail" do
      expected = content_tag :span, title: "Commuter Rail", class: "route-icon route-icon-commuter-rail" do
        svg("commuter-rail.svg")
      end
      assert mode_icon(:commuter_rail) == expected
    end
  end

  describe "external_link/1" do
    test "Protocol is added when one is not included" do
      assert external_link("http://www.google.com") == "http://www.google.com"
      assert external_link("www.google.com") == "http://www.google.com"
      assert external_link("https://google.com") == "https://google.com"
    end
  end

  describe "strip_protocol/1" do
    test "Protocol is removed when one is present" do
      assert strip_protocol("http://www.google.com") == "www.google.com"
      assert strip_protocol("www.google.com") == "www.google.com"
      assert strip_protocol("https://google.com") == "google.com"
    end
  end

  describe "subway_name/1" do
    test "All Green line routes display \"Green Line\"" do
      assert subway_name("Green-B") == "Green Line"
      assert subway_name("Green-C") == "Green Line"
      assert subway_name("Green-D") == "Green Line"
      assert subway_name("Green-E") == "Green Line"
    end
    test "Lines show correct display name" do
      assert subway_name("Red Line") == "Red Line"
      assert subway_name("Mattapan") == "Red Line"
      assert subway_name("Blue Line") == "Blue Line"
      assert subway_name("Orange Line") == "Orange Line"
    end
  end

  describe "mode_string/1" do
    test "converts the atom to a dash delimted string" do
      assert hyphenated_mode_string(:the_ride) == "the-ride"
      assert hyphenated_mode_string(:bus) == "bus"
      assert hyphenated_mode_string(:subway) == "subway"
      assert hyphenated_mode_string(:commuter_rail) == "commuter-rail"
      assert hyphenated_mode_string(:ferry) == "ferry"
    end
  end
end
