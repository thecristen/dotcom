defmodule Site.ScheduleController.AllStopsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleController.AllStops

  test "deduplicates red line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, nil)
    |> assign(:direction_id, 1)
    |> assign(:route, %Routes.Route{id: "Red"})
    |> AllStops.call([])

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end
end
