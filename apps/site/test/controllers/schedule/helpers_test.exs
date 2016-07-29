defmodule Site.ScheduleController.HelpersTest do
  use Site.ConnCase, async: true

  test "assign_all_stops deduplicates red line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, nil)
    |> assign(:direction_id, 1)
    |> Site.ScheduleController.Helpers.assign_all_stops("Red")

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end
end
