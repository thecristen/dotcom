defmodule Site.ScheduleController.Pairs do
  use Site.Web, :controller

  import Site.ScheduleController.Defaults
  import Site.ScheduleController.Helpers

  def pairs(conn, origin_id, dest_id) do
    conn = conn
    |> default_assigns
    |> assign_alerts

    opts = []
    |> Dict.put(:direction_id, conn.assigns[:direction_id])
    |> Dict.put(:date, conn.assigns[:date])

    pairs = Schedules.Repo.origin_destination(origin_id, dest_id, opts)

    general_route = pairs
    |> Enum.map(fn {stop, _} -> stop.route end)
    |> most_frequent_value

    {filtered_pairs, conn} = pairs
    |> Enum.filter(fn {_, dest} -> is_after_now?(dest) end)
    |> possibly_open_schedules(pairs, conn)

    conn
    |> assign(:route, general_route)
    |> assign_all_routes
    |> await_assign_all
    |> render("pairs.html",
      from: pairs |> List.first |> (fn {x, _} -> x.stop.name end).(),
      to: pairs |> List.first |> (fn {_, y} -> y.stop.name end).(),
      pairs: filtered_pairs
    )
  end
end
