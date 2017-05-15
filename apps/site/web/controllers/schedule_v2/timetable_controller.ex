defmodule Site.ScheduleV2Controller.TimetableController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug :tab_name
  plug Site.ScheduleV2Controller.Core
  plug :assign_trip_schedules
  plug Site.ScheduleV2Controller.Offset

  def show(conn, _) do
    render(conn, Site.ScheduleV2View, "show.html")
  end

  # Plug that assigns trip schedule to the connection
  defp assign_trip_schedules(conn, _) do
    timetable_schedules = timetable_schedules(conn)
    header_schedules = header_schedules(timetable_schedules)
    trip_schedules = Map.new(timetable_schedules, & {{&1.trip.id, &1.stop.id}, &1})

    conn
    |> assign(:timetable_schedules, timetable_schedules)
    |> assign(:header_schedules, header_schedules)
    |> assign(:trip_schedules, trip_schedules)
    |> assign(:trip_messages, trip_messages(conn.assigns.route, conn.assigns.direction_id))
  end

  # Helper function for obtaining schedule data
  @spec timetable_schedules(Plug.Conn.t) :: [Schedules.Schedule.t]
  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    case Schedules.Repo.by_route_ids([route.id], date: date, direction_id: direction_id) do
      {:error, _} -> []
      schedules -> schedules
    end
  end

  @spec header_schedules(list) :: list
  defp header_schedules(timetable_schedules) do
    timetable_schedules
    |> Schedules.Sort.sort_by_first_times
    |> Enum.map(&List.first/1)
  end

  @spec trip_messages(Routes.Route.t, 0 | 1) :: %{{String.t, String.t} => String.t}
  defp trip_messages(%Routes.Route{id: "CR-Lowell"}, 0) do
    %{
      {"221", "North Billerica"} => "Via",
      {"221", "Lowell"} => "Haverhill"
    }
  end
  defp trip_messages(%Routes.Route{id: "CR-Haverhill"}, 0) do
    %{
      {"221", "Melrose Highlands"} => "Via",
      {"221", "Greenwood"} => "Lowell"
    }
  end
  defp trip_messages(%Routes.Route{id: "CR-Franklin"}, 1) do
    %{
      {"790", "place-rugg"} => "Via",
      {"790", "place-bbsta"} => "Fairmount",
      {"746", "place-rugg"} => "Via",
      {"746", "place-bbsta"} => "Fairmount"
    }
  end
  defp trip_messages(_, _) do
    %{}
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "timetable")
end
