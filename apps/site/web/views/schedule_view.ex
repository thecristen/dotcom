defmodule Site.ScheduleView do
  use Site.Web, :view
  alias Routes.Route
  alias Schedules.Schedule

  def stop_alerts_for(alerts, stop_ids, opts) do
    stop_ids
    |> Enum.flat_map(fn id -> Alerts.Stop.match(alerts, id, opts) end)
    |> Enum.uniq
  end

  def trip_alerts_for(_, []), do: []
  def trip_alerts_for(alerts, [schedule|_] = schedules) do
    trip_ids = schedules
    |> Enum.map(fn schedule -> schedule.trip.id end)

    Alerts.Trip.match(
      alerts,
      trip_ids,
      time: schedule.time,
      route: schedule.route.id,
      route_type: schedule.route.type,
      direction_id: schedule.trip.direction_id,
      stop: schedule.stop.id
    )
  end
  def trip_alerts_for(alerts, schedule) do
    trip_alerts_for(alerts, [schedule])
  end

  def update_url(%{params: params} = conn, query) do
    params = params || %{}
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
    |> Enum.into(%{})

    new_query = params
    |> Map.merge(query_map)
    |> Enum.reject(&empty_value?/1)
    |> Enum.into(%{})

    {route, new_query} = Map.pop(new_query, "route")

    schedule_path(conn, :show, route, new_query |> Enum.into([]))
  end

  @doc """
  Puts the conn into the assigns dictionary so that downstream templates can use it
  """
  def forward_assigns(%{assigns: assigns} = conn) do
    assigns
    |> Dict.put(:conn, conn)
  end

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, _}), do: false

  @doc "Link a station's name to its page, if it exists. Otherwise, just returns the name."
  def station_name_as_link(station) do
    case Stations.Repo.get(station.id) do
      nil -> station.name
      _ -> link station.name, to: station_path(Site.Endpoint, :show, station.id)
    end
  end

  def station_info_link(station) do
    do_station_info_link(Stations.Repo.get(station.id))
  end

  defp do_station_info_link(nil) do
    raw ""
  end
  defp do_station_info_link(%{id: id, name: name}) do
    title = "View station information for #{name}"
    body = ~e(
      <%= fa "map-o" %>
      <span class="sr-or-no-js"> <%= title %>
    )

    link(
      to: station_path(Site.Endpoint, :show, id),
      class: "station-info-link",
      data: [
        toggle: "tooltip"
      ],
      title: title,
      do: body)
  end

  def reverse_direction_opts(origin, dest, route_id, direction_id) do
    new_origin = dest || origin
    new_dest = dest && origin
    [trip: nil, direction_id: direction_id, route: route_id]
    |> Keyword.merge(
      if Schedules.Repo.stop_exists_on_route?(new_origin, route_id, direction_id) do
        [dest: new_dest, origin: new_origin]
      else
        [dest: nil, origin: nil]
      end
    )
  end

  def most_frequent_headsign(schedules) do
    schedules
    |> Enum.map(&(&1.trip.headsign))
    |> Util.most_frequent_value
  end

  def trip(schedules, from_id, to_id) do
    schedules
    |> filter_beginning(from_id)
    |> filter_end(to_id)
  end

  defp filter_beginning(schedules, from_id) do
    Enum.drop_while(schedules, &(&1.stop.id !== from_id))
  end

  defp filter_end(schedules, nil) do
    schedules
  end
  defp filter_end(schedules, to_id) do
    schedules
    |> Enum.reverse
    |> Enum.drop_while(&(&1.stop.id !== to_id))
    |> Enum.reverse
  end

  @doc "Return the icon for the schedule row depending on whether it's selected"
  def selected_caret(true) do
    fa "caret-up pull-right"
  end
  def selected_caret(false) do
    fa "caret-down pull-right"
  end

  def schedule_list(schedules, true) do
    schedules
  end
  def schedule_list(schedules, false) do
    Enum.slice(schedules, 0..8)
  end

  def get_hour(%{params: %{"hour" => hour}}), do: hour
  def get_hour(_), do: Util.now.hour |> to_string

  def get_schedule_name(%{params: %{"name" => name}}), do: name
  def get_schedule_name(_) do
    Util.now
    |> TimeGroup.subway_period
    |> to_string
  end

  def prediction_for_schedule(predictions, %Schedule{trip: %{id: trip_id}, stop: %{id: stop_id}}) do
    predictions
    |> Enum.find(fn
      %{trip_id: ^trip_id, stop_id: ^stop_id} -> true
      _ -> false
    end)
  end
end
