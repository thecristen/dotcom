defmodule Site.FareControllerTest do
  use Site.ConnCase, async: true
  import Site.FareController
  alias Fares.{Fare, Summary}
  alias Site.FareController.Filter

  describe "index" do
    test "renders", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert html_response(conn, 200) =~ "Fares and Passes"
    end

    test "includes 4 summarized bus/subway fares", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert [%Summary{}, _, _, _] = conn.assigns.bus_subway
    end

    test "includes 2 summarized Commuter Rail fares", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert [%Summary{}, _] = conn.assigns.commuter_rail
    end

    test "includes 2 summarized Ferry fares", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert [%Summary{}, _] = conn.assigns.ferry
    end
  end

  test "renders commuter rail", %{conn: conn} do
    conn = get conn, fare_path(conn, :show, :commuter_rail, origin: "place-sstat", destination: "Readville")
    assert html_response(conn, 200) =~ "Commuter Rail Fares"
  end

  test "renders ferry", %{conn: conn} do
    conn = get conn, fare_path(conn, :show, :ferry, origin: "Boat-Long", destination: "Boat-Logan")
    response = html_response(conn, 200)
    assert response =~ "Ferry Fares"
    assert response =~ "Valid between Long Wharf, Boston and Logan Ferry Terminal only."
  end

  test "renders bus/subway", %{conn: conn} do
    conn = get conn, fare_path(conn, :show, :bus_subway)
    assert html_response(conn, 200) =~ "Bus and Subway Fares"
  end

  test "lists vending machine stations on bus/subway page", %{conn: conn} do
    conn = get conn, fare_path(conn, :show, :bus_subway)
    for station  <- ["Back Bay", "Braintree", "Forest Hills", "JFK/UMass", "Lynn", "Malden Center", "North Station",
    "Porter Square", "Quincy Center", "Ruggles", "South Station", "Worcester/Union"] do
      assert html_response(conn, 200) =~ station
    end
  end

  test "lists charliecard stations on bus/subway page", %{conn: conn} do
    conn = get conn, fare_path(conn, :show, :bus_subway)
    for station <- ["Alewife", "Arlington", "Ashmont", "Back Bay", "Dudley Square", "Forest Hills", "Harvard Square",
    "North Station", "Oak Grove", "Park", "Ruggles"] do
      assert html_response(conn, 200) =~ station
    end
  end

  describe "filter_reduced/2" do
    @fares [%Fare{name: {:zone, "6"}, reduced: nil},
            %Fare{name: {:zone, "5"}, reduced: nil},
            %Fare{name: {:zone, "6"}, reduced: :student}]

    test "filters out non-adult fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: nil},
                        %Fare{name: {:zone, "5"}, reduced: nil}]
      assert filter_reduced(@fares, nil) == expected_fares
    end

    test "filters out non-student fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: :student}]
      assert filter_reduced(@fares, :student) == expected_fares
    end
  end

  describe "selected_filter" do
    @filters [
      %Filter{id: "1"},
      %Filter{id: "2"}
    ]

    test "defaults to returning the first filter" do
      assert selected_filter(@filters, nil) == List.first(@filters)
      assert selected_filter(@filters, "unknown") == List.first(@filters)
    end

    test "returns the filter based on the id" do
      assert selected_filter(@filters, "1") == List.first(@filters)
      assert selected_filter(@filters, "2") == List.last(@filters)
    end

    test "if there are no filters, return nil" do
      assert selected_filter([], "1") == nil
    end
  end

  describe "payment methods page" do
    test "renders payment info" do
      conn = get build_conn(), fare_path(Site.Endpoint, :show, "payment_methods")
      content = html_response(conn, 200)
      assert content =~ "CharlieCards are durable, plastic cards"
      assert content =~ "Pick up a CharlieTicket at"
      assert content =~ "Commuter Rail and Ferry riders can easily purchase any pass"
      assert content =~ "Each mode accepts cash on-board"
    end
  end
end
