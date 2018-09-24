defmodule SiteWeb.ScheduleController.AllStopsTest do
  use SiteWeb.ConnCase, async: true
  alias SiteWeb.ScheduleController.AllStops

  @moduletag :external

  test "gets all Blue line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, Util.service_date())
    |> assign(:direction_id, 1)
    |> assign(:route, %Routes.Route{id: "Blue"})
    |> AllStops.call([])

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) > 0
    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end

  test "gets all Red line stops and adds wollaston", %{conn: conn} do
    conn = conn
    |> assign(:date, Util.service_date())
    |> assign(:direction_id, 1)
    |> assign(:route, %Routes.Route{id: "Red"})
    |> AllStops.call([])

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) > 0
    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
    assert Enum.find(all_stops, fn s -> s.id == "place-wstn" end)
  end
end
