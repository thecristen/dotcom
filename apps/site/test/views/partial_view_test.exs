defmodule Site.PartialViewTest do
  use Site.ConnCase, async: true

  import Site.PartialView
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "stop_selector_suffix/2" do
    test "returns zones for commuter rail", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 2})
      |> assign(:zone_map, %{"Lowell" => "6"})

      assert conn |> stop_selector_suffix("Lowell") |> IO.iodata_to_binary == "Zone 6"
    end

    test "if the stop has no zone, returns the empty string", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 2})
      |> assign(:zone_map, %{})

      assert stop_selector_suffix(conn, "Wachusett")  == ""
    end

    test "returns a comma-separated list of lines for the green line", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{id: "Green"})
      |> assign(:stops_on_routes, GreenLine.stops_on_routes(0))

      assert conn |> stop_selector_suffix("place-pktrm") |> IO.iodata_to_binary == "B,C,D,E"
      assert conn |> stop_selector_suffix("place-lech") |> IO.iodata_to_binary == "E"
      assert conn |> stop_selector_suffix("place-kencl") |> IO.iodata_to_binary == "B,C,D"
    end

    test "for other lines, returns the empty string", %{conn: conn} do
      assert stop_selector_suffix(conn, "place-harsq") == ""
    end
  end

  describe "clear_selector_link/1" do
    test "returns the empty string when clearable? is false" do
      assert clear_selector_link(%{clearable?: false, selected: "place-davis"}) == ""
    end

    test "returns the empty string when selecte is nil" do
      assert clear_selector_link(%{clearable?: true, selected: nil}) == ""
    end

    test "otherwise returns a link setting the query_key to nil", %{conn: conn} do
      result = %{
        clearable?: true,
        selected: "place-davis",
        placeholder_text: "destination",
        query_key: "destination",
        conn: fetch_query_params(conn)
      }
      |> clear_selector_link()
      |> safe_to_string

      assert result =~ "(clear<span class=\"sr-only\"> destination</span>)"
      refute result =~ "place-davis"
    end
  end

end
