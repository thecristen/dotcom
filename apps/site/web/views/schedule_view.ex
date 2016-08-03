defmodule Site.ScheduleView do
  use Site.Web, :view

  def update_url(%{params: params} = conn, query) do
    query_map = query
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
    |> Enum.into(%{})

    new_query = params
    |> Map.merge(query_map)
    |> Enum.into([])
    |> Enum.reject(&empty_value?/1)

    schedule_path(conn, :index, new_query)
  end

  @doc """
  Puts the conn into the assigns dictionary so that downstream templates can use it
  """
  def forward_assigns(%{assigns: assigns} = conn) do
    assigns
    |> Dict.put(:conn, conn)
  end

  def has_alerts?(alerts, %Schedules.Schedule{} = schedule) do
    entity = %Alerts.InformedEntity{
      route_type: schedule.route.type,
      route: schedule.route.id,
      stop: schedule.stop.id,
      trip: schedule.trip.id
    }

    # hack to unmatch the "Fares go up on July 1" alert on everything
    matched = alerts
    |> Alerts.Match.match(entity, schedule.time)
    |> Enum.reject(&Alerts.Alert.is_notice?/1)

    matched != []
  end
  def has_alerts?(alerts, %Schedules.Trip{} = trip) do
    entity = %Alerts.InformedEntity{
      trip: trip.id
    }

    matched = alerts
    |> Alerts.Match.match(entity)
    |> Enum.reject(&Alerts.Alert.is_notice?/1)

    matched != []
  end

  @doc """
  Partition a enum of alerts into a pair of those that should be displayed as alerts, and those
  that should be displayed as notices.
  """
  def notices_and_alerts(alerts) do
    alerts
    |> Enum.partition(&Alerts.Alert.is_notice?/1)
  end

  @doc """
  Takes a list of alerts and returns a string summarizing their effects, such as "3 Delays, Stop
  Closure, 4 Station Issues". Adds an optional suffix if the list of alerts is non-empty.
  """
  def display_alert_effects(alerts, suffix \\ "")
  def display_alert_effects([], _), do: ""
  def display_alert_effects(alerts, suffix) do
    alerts
    |> Enum.group_by(&(&1.effect_name))
    |> Enum.map(fn {effect_name, alerts} ->
      num_alerts = length(alerts)
      if num_alerts > 1 do
        "#{num_alerts} #{Inflex.inflect(effect_name, num_alerts)}"
      else
        effect_name
      end
    end)
    |> Enum.join(", ")
    |> Kernel.<>(suffix)
  end

  def display_alert_updated(alert) do
    formatted = alert.updated_at
    |> Timex.format!("{relative}", Timex.Format.DateTime.Formatters.Relative)

    "Updated #{formatted}"
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

  def newline_to_br(text) do
    import Phoenix.HTML

    text
    |> html_escape
    |> safe_to_string
    |> String.replace("\n", "<br />")
    |> raw
  end

  @doc "Link a station's name to its page, if it exists. Otherwise, just returns the name."
  def station_link(station) do
    case Stations.Repo.get(station.id) do
      nil -> station.name
      _ -> link station.name, to: station_path(Site.Endpoint, :show, station.id)
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
