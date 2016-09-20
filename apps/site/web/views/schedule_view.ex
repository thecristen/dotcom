defmodule Site.ScheduleView do
  use Site.Web, :view
  alias Routes.Route

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

  def hidden_query_params(conn, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    include = Keyword.get(opts, :include, %{})
    conn.query_params
    |> Map.merge(include)
    |> Enum.reject(fn {key, _} -> key in exclude end)
    |> Enum.uniq_by(fn {key, _} -> to_string(key) end)
    |> Enum.map(&hidden_tag/1)
  end

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, _}), do: false

  defp hidden_tag({key, value}) do
    tag :input, type: "hidden", name: key, value: value
  end

  @doc "Link a station's name to its page, if it exists. Otherwise, just returns the name."
  def station_name_as_link(station) do
    case Stations.Repo.get(station.id) do
      nil -> station.name
      _ -> link station.name, to: station_path(Site.Endpoint, :show, station.id)
    end
  end

  def station_info_link(station, [do: block]) do
    url = station_path(Site.Endpoint, :show, station.id)
    case Stations.Repo.get(station.id) do
      nil -> ""
      _ -> link(to: url, do: block)
    end
  end

  def map_icon_link(station) do
    case Stations.Repo.get(station.id) do
      nil -> station.name
      _ -> link fa("map-o"), to: station_path(Site.Endpoint, :show, station.id)
    end
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

  @doc "Prefix route name with route for bus lines"
  def header_text(3, name), do: "Route #{name}"
  def header_text(2, name), do: Site.ViewHelpers.clean_route_name(name)
  def header_text(_, name), do: "#{name}"

  def get_hour(%{params: %{"hour" => hour}}), do: hour
  def get_hour(_), do: Util.now.hour |> to_string

  def get_schedule_name(%{params: %{"name" => name}}), do: name
  def get_schedule_name(_) do
    Util.now
    |> TimeGroup.subway_period
    |> to_string
  end
end
