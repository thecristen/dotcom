defmodule SiteWeb.ScheduleController.AllStopsTest do
  use SiteWeb.ConnCase, async: true
  alias SiteWeb.ScheduleController.AllStops

  @moduletag :external

  test "gets all Blue line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, Util.service_date())
    |> assign(:date_in_rating?, true)
    |> assign(:direction_id, 1)
    |> assign(:route, %Routes.Route{id: "Blue"})
    |> AllStops.call([repo_fn: &Stops.Repo.by_route/3])

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) > 0
    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end

  test "gets all Red line stops and adds wollaston", %{conn: conn} do
    conn = conn
    |> assign(:date, Util.service_date())
    |> assign(:date_in_rating?, true)
    |> assign(:direction_id, 1)
    |> assign(:route, %Routes.Route{id: "Red"})
    |> AllStops.call([repo_fn: &Stops.Repo.by_route/3])

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) > 0
    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
    assert Enum.find(all_stops, fn s -> s.id == "place-wstn" end)
  end

  test "still fetches stops if provided date is outside of the rating", %{conn: conn} do
    date =
      Schedules.Repo.end_of_rating()
      |> Timex.shift(days: 2)

    assert %Plug.Conn{assigns: %{all_stops: outside_rating}} =
      conn
      |> assign(:date, date)
      |> assign(:date_in_rating?, false)
      |> assign(:direction_id, 1)
      |> assign(:route, %Routes.Route{id: "Red"})
      |> AllStops.call([repo_fn: &Stops.Repo.by_route/3])


    assert %Plug.Conn{assigns: %{all_stops: today}} =
      conn
      |> assign(:date, Util.service_date())
      |> assign(:date_in_rating?, true)
      |> assign(:direction_id, 1)
      |> assign(:route, %Routes.Route{id: "Red"})
      |> AllStops.call([repo_fn: &Stops.Repo.by_route/3])

    refute Enum.empty?(outside_rating)
    assert outside_rating == today
  end

  test "returns an empty list if repo returns {:error, _}", %{conn: conn} do
    date = Util.service_date()
    repo_fn = fn "Red", 1, [date: ^date] ->
      {:error, "error"}
    end

    conn =
      conn
      |> assign(:date, date)
      |> assign(:date_in_rating?, true)
      |> assign(:direction_id, 1)
      |> assign(:route, %Routes.Route{id: "Red"})
      |> AllStops.call([repo_fn: repo_fn])
    assert conn.assigns.all_stops == []
  end
end
