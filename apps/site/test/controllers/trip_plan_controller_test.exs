defmodule Site.TripPlanControllerTest do
  use Site.ConnCase, async: true
  alias Site.TripPlan.Query
  alias Site.PartialView.StopBubbles
  import Phoenix.HTML, only: [html_escape: 1, safe_to_string: 1]

  @valid_date_time Timex.shift(Util.now(), minutes: +5)
  @valid_date_input %{"year" => Timex.format!(@valid_date_time, "{YYYY}"),
              "month" => Timex.format!(@valid_date_time, "{M}"),
              "day" => Timex.format!(@valid_date_time, "{D}"),
              "hour" => Timex.format!(@valid_date_time, "{h24}"),
              "minute" => Timex.format!(@valid_date_time, "{m}")}

  @good_params %{
    "plan" => %{"from" => "from address",
                "to" => "to address",
                "date_time" => @valid_date_input}
  }
  @bad_params %{
    "plan" => %{"from" => "no results",
                "to" => "too many results",
                "date_time" => @valid_date_input}
  }

  describe "index without params" do
    test "renders index.html", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index)
      assert html_response(conn, 200) =~ "Directions"
      assert conn.assigns.requires_google_maps?
    end

    test "assigns initial_map_src", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index)
      assert conn.assigns.initial_map_src
    end
  end

  describe "index with params" do

    test "renders the query plan", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      response = html_response(conn, 200)
      assert response =~ "Directions"
      assert response =~ "Itinerary 1"
      assert conn.assigns.requires_google_maps?
      assert %Query{} = conn.assigns.query
      assert Map.size(conn.assigns.route_map) > 0
    end

    test "uses current location to render a query plan", %{conn: conn} do
      params = %{
        "plan" => %{"from" => "Current Location",
                    "from_latitude" => "42.3428",
                    "from_longitude" => "-71.0857",
                    "to" => "to address",
                    "to_latitude" => "",
                    "to_longitude" => "",
                    "date_time" => @valid_date_input
                   }
      }
      conn = get conn, trip_plan_path(conn, :index, params)

      assert html_response(conn, 200) =~ "Directions"
      assert conn.assigns.requires_google_maps?
      assert %Query{} = conn.assigns.query
      assert Map.size(conn.assigns.route_map) > 0
    end

    test "each map url has a path color", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      for {map_data, static_map} <- conn.assigns.itinerary_maps do
        assert static_map =~ "color"
        for path <- map_data.paths do
          assert path.color
        end
      end
    end

    test "renders a geocoding error", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @bad_params)
      response = html_response(conn, 200)
      assert response =~ "Directions"
      assert response =~ "Did you mean?"
      assert conn.assigns.requires_google_maps?
      assert %Query{} = conn.assigns.query
    end

    test "renders a prereq error with the initial map", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, plan: %{"from" => "", "to" => ""})
      response = html_response(conn, 200)
      assert response =~ conn.assigns.initial_map_src |> html_escape |> safe_to_string
    end

    test "assigns maps for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert conn.assigns.itinerary_maps
      for {_map_data, static_map} <- conn.assigns.itinerary_maps do
        assert static_map =~ "https://maps.googleapis.com/maps/api/staticmap"
      end
    end

    test "assigns an ItineraryRowList for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert conn.assigns.itinerary_row_lists
    end

    test "assigns a list of alerts for each itinerary", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      {:ok, itineraries} = conn.assigns.query.itineraries
      assert length(itineraries) == length(conn.assigns.alerts)
    end

    test "assigns a list of lists of stop bubble params for the itineraries", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert length(conn.assigns.itinerary_row_lists) == length(conn.assigns.stop_bubble_params_list)
      conn.assigns.itinerary_row_lists
      |> Enum.zip(conn.assigns.stop_bubble_params_list)
      |> Enum.all?(fn {rows, params} -> Enum.count(rows) == Enum.count(params) end)
      |> assert

      [itinerary_stop_bubble_params | _] = conn.assigns.stop_bubble_params_list
      [first_row | rest_rows] = itinerary_stop_bubble_params
      assert %StopBubbles.Params{bubbles: [{nil, :terminus}]} = first_row
      rest_rows
      |> Enum.all?(fn params -> match?(%StopBubbles.Params{bubbles: [{nil, :stop}]}, params) end)
      |> assert
    end

    test "assigns stop bubble params for the destination", %{conn: conn} do
      conn = get conn, trip_plan_path(conn, :index, @good_params)
      assert length(conn.assigns.itinerary_row_lists) == length(conn.assigns.destination_stop_bubble_params_list)
      conn.assigns.destination_stop_bubble_params_list
      |> Enum.all?(fn params -> match?(%StopBubbles.Params{bubbles: [{nil, :terminus}]}, params) end)
      |> assert
    end

    test "bad date input: fictional day", %{conn: conn} do
      date_time = Timex.shift(Util.now(), years: +1)
      date_input = %{"year" => Timex.format!(date_time, "{YYYY}"),
                   "month" => "6",
                   "day" => "31",
                   "hour" => Timex.format!(date_time, "{h24}"),
                   "minute" => Timex.format!(date_time, "{m}")}

      params = %{
        "plan" => %{"from" => "from address",
                    "to" => "to address",
                    "date_time" => date_input
                   }}

      conn = get conn, trip_plan_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Please choose a valid date"
    end

    test "bad date input: partial input", %{conn: conn} do
      date_time = Timex.shift(Util.now(), years: +1)
      date_input = %{"year" => Timex.format!(date_time, "{YYYY}"),
                   "month" => "",
                   "day" => "31",
                   "hour" => Timex.format!(date_time, "{h24}"),
                   "minute" => Timex.format!(date_time, "{m}")}

      params = %{
        "plan" => %{"from" => "from address",
                    "to" => "to address",
                    "date_time" => date_input
                   }}

      conn = get conn, trip_plan_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Please choose a valid date"
    end

    test "bad date input: corrupt day", %{conn: conn} do
      date_input = %{"year" => "A",
                   "month" => "B",
                   "day" => "C",
                   "hour" => "D",
                   "minute" => "E"}

      params = %{
        "plan" => %{"from" => "from address",
                    "to" => "to address",
                    "date_time" => date_input
                   }}

      conn = get conn, trip_plan_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Please choose a valid date"
    end

    test "bad date input: date passed", %{conn: conn} do
      date_time = Timex.shift(Util.now(), days: -1)
      date_input = %{"year" => Timex.format!(date_time, "{YYYY}"),
                   "month" => Timex.format!(date_time, "{M}"),
                   "day" => Timex.format!(date_time, "{D}"),
                   "hour" => Timex.format!(date_time, "{h24}"),
                   "minute" => Timex.format!(date_time, "{m}")}

      params = %{
        "plan" => %{"from" => "from address",
                    "to" => "to address",
                    "date_time" => date_input
                   }}

      conn = get conn, trip_plan_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Please select a date in the future"
    end
  end
end
