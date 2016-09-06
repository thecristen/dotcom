defmodule Site.ScheduleView do
  use Site.Web, :view

  def stop_alerts_for(alerts, stop_ids, opts) do
    stop_ids
    |> Enum.flat_map(fn id -> Alerts.Stop.match(alerts, id, opts) end)
    |> Enum.uniq
  end

  def trip_alerts_for(_, []), do: []
  def trip_alerts_for(alerts, [schedule|_]=schedules) do
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
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
    |> Enum.into(%{})

    new_query = params
    |> Map.merge(query_map)
    |> Enum.into([])
    |> Enum.reject(&empty_value?/1)

    schedule_path(conn, :show, params["route"], new_query)
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
    conn.params
    |> Enum.reject(fn {key, _} -> key in exclude end)
    |> Enum.map(&hidden_tag/1)
  end

  defp empty_value?({_, value}) do
    value in ["", nil]
  end

  defp hidden_tag({key, value}) do
    tag :input, type: "hidden", name: key, value: value
  end

  @doc "Link a station's name to its page, if it exists. Otherwise, just returns the name."
  def station_name_as_link(station) do
    import Phoenix.HTML
    case Stations.Repo.get(station.id) do
      nil -> station.name
      _ -> link station.name, to: station_path(Site.Endpoint, :show, station.id)
    end
  end

  def station_info_link(station) do
    import Phoenix.HTML
    case Stations.Repo.get(station.id) do
      nil -> ""
      _ -> "(<a href='#{station_path(Site.Endpoint, :show, station.id)}'>View station info</a>)" |> raw
    end
  end


  def reverse_direction_opts(origin, dest, route_id, direction_id) do
    new_origin = dest || origin
    new_dest = dest && origin
    [trip: "", direction_id: direction_id, route: route_id]
    |> Keyword.merge(
      if Schedules.Repo.stop_exists_on_route?(new_origin, route_id, direction_id) do
        [dest: new_dest, origin: new_origin]
      else
        [dest: nil, origin: nil]
      end
    )
  end
end
