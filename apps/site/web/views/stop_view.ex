defmodule Site.StopView do
  use Site.Web, :view

  alias Fares.Summary
  alias Stops.Stop

  @origin_stations ["place-north", "place-sstat", "place-rugg", "place-bbsta"]

  @doc "Specify the mode each type is associated with"
  @spec fare_group(atom) :: String.t
  def fare_group(:bus), do: "bus_subway"
  def fare_group(:subway), do: "bus_subway"
  def fare_group(type), do: Atom.to_string(type)

  def location(stop) do
    case stop.latitude do
      nil -> URI.encode(stop.address, &URI.char_unreserved?/1)
      _ -> "#{stop.latitude},#{stop.longitude}"
    end
  end

  def pretty_accessibility("tty_phone"), do: "TTY Phone"
  def pretty_accessibility("escalator_both"), do: "Escalator (Both)"
  def pretty_accessibility(accessibility) do
    accessibility
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def optional_li(""), do: ""
  def optional_li(nil), do: ""
  def optional_li(value) do
    content_tag :li, value
  end

  def optional_link("", _) do
    nil
  end
  def optional_link(href, value) do
    content_tag(:a, value, href: external_link(href), target: "_blank")
  end

  def sort_parking_spots(spots) do
    spots
    |> Enum.sort_by(fn %{type: type} ->
      case type do
        "basic" -> 0
        "accessible" -> 1
        _ -> 2
      end
    end)
  end

  @spec mode_summaries(atom, {atom, String.t}) :: [Summary.t]
  @doc "Return the fare summaries for the given mode"
  def mode_summaries(:commuter, name) do
    filters = mode_filters(:commuter, name)
    summaries_for_filters(filters, :bus_subway) |> Enum.map(fn(summary) -> %{summary | modes: [:commuter]} end)
  end
  def mode_summaries(:ferry, name) do
    summaries_for_filters(mode_filters(:ferry, name), :ferry)
  end
  def mode_summaries(:bus, name) do
    summaries_for_filters(mode_filters(:local_bus, name), :bus_subway)
  end
  def mode_summaries(mode, name) do
    summaries_for_filters(mode_filters(mode, name), :bus_subway)
  end

  @spec mode_filters(atom, {atom, String.t}) :: [keyword()]
  defp mode_filters(:ferry, _name) do
    [[mode: :ferry, duration: :single_trip, reduced: nil],
     [mode: :ferry, duration: :month, reduced: nil]]
  end
  defp mode_filters(:commuter, name) do
    [[mode: :commuter, duration: :single_trip, reduced: nil, name: name],
     [mode: :commuter, duration: :month, media: [:commuter_ticket], reduced: nil, name: name]]
  end
  defp mode_filters(:bus_subway, name) do
    [[name: :local_bus, duration: :single_trip, reduced: nil] | mode_filters(:subway, name)]
  end
  defp mode_filters(mode, _name) do
    [[name: mode, duration: :single_trip, reduced: nil],
     [name: mode, duration: :week, reduced: nil],
     [name: mode, duration: :month, reduced: nil]]
  end

  @spec fare_mode([atom]) :: atom
  @doc "Determine what combination of bus and subway are present in given types"
  def fare_mode(types) do
    cond do
      :subway in types && :bus in types -> :bus_subway
      :subway in types -> :subway
      :bus in types -> :bus
    end
  end

  @spec aggregate_routes([map()]) :: [map()]
  @doc "Combine multipe routes on the same subway line"
  def aggregate_routes(routes) do
    routes
    |> Enum.map(&(if String.starts_with?(&1.name, "Green"), do: %{&1 | name: "Green"}, else: &1))
    |> Enum.map(&(if &1.name == "Mattapan", do: %{&1 | name: "Red"}, else: &1))
    |> Enum.uniq_by(&(&1.name))
  end

  @spec accessibility_info(Stop.t) :: [Phoenix.HTML.Safe.t]
  @doc "Accessibility content for given stop"
  def accessibility_info(stop) do
    [(content_tag :p, format_accessibility_text(stop.name, stop.accessibility)),
    format_accessibility_options(stop)]
  end

  @spec format_accessibility_options(Stop.t) :: Phoenix.HTML.Safe.t | nil
  defp format_accessibility_options(stop) do
    if stop.accessibility && !Enum.empty?(stop.accessibility) do
      content_tag :p do
        stop.accessibility
        |> Enum.filter(&(&1 != "accessible"))
        |> Enum.map(&pretty_accessibility/1)
        |> Enum.join(", ")
      end
    else
      content_tag :span, ""
    end
  end

  @spec format_accessibility_text(String.t, [String.t]) :: Phoenix.HTML.Safe.t
  defp format_accessibility_text(name, nil), do: content_tag(:em, "No accessibility information available for #{name}")
  defp format_accessibility_text(name, []), do: content_tag(:em, "No accessibility information available for #{name}")
  defp format_accessibility_text(name, ["accessible"]) do
    content_tag(:span, "#{name} is an accessible station. Accessible stations can be accessed by wheeled mobility devices.")
  end
  defp format_accessibility_text(name, _features), do: content_tag(:span, "#{name} has the following accessibility features:")

  @spec show_fares?(Stop.t) :: boolean
  @doc "Determines if the fare information for the given stop should be displayed"
  def show_fares?(stop) do
    !stop.id in @origin_stations
  end

  @spec summaries_for_filters([keyword()], atom) :: [Summary.t]
  defp summaries_for_filters(filters, mode) do
    filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(mode)
  end

  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("info"), do: "_info.html"
  def template_for_tab(_tab), do: "_schedule.html"

  @spec tab_class(String.t, String.t) :: String.t
  @doc "Given a station tab, and the selected tab, returns the CSS class for the given station tab"
  def tab_class(tab, tab), do: "stations-tab stations-tab-selected"
  def tab_class("schedule", nil), do: "stations-tab stations-tab-selected"
  def tab_class(_, _), do: "stations-tab"

  @spec schedule_template(Routes.Route.route_type) :: String.t
  @doc "Returns the template to render schedules for the given mode."
  def schedule_template(:commuter), do: "_commuter_schedule.html"
  def schedule_template(_), do: "_mode_schedule.html"

  @spec has_alerts?(Plug.Conn.t, Alerts.InformedEntity.t) :: boolean
  @doc "Returns true if the given route has alerts. The date is supplied by the conn."
  def has_alerts?(conn, informed_entity) do
    Alerts.Repo.all
    |> Enum.reject(&Alerts.Alert.is_notice?/1)
    |> Alerts.Match.match(informed_entity, conn.assigns[:date])
    |> Enum.empty?
    |> Kernel.not
  end

  @spec upcoming_commuter_departures(Plug.Conn.t, String.t, String.t, integer) :: Schedules.Schedule.t | nil
  @doc "Returns the next departure for the given stop, CR line, and direction."
  def upcoming_commuter_departures(conn, stop, route, direction_id) do
    stop
    |> Schedules.Repo.schedule_for_stop(route: route, date: conn.assigns[:date], direction_id: direction_id)
    |> Enum.find(&(Timex.after?(&1.time, conn.assigns[:date_time]) && departing?(&1.trip.id, stop)))
  end

  @spec upcoming_departures(Plug.Conn.t, String.t, String.t, integer) :: [{:scheduled | :predicted, String.t, DateTime.t}]
  @doc "Returns the next departures for the given stop, route, and direction."
  def upcoming_departures(conn, stop_id, route_id, direction_id) do
    predicted = [stop: stop_id, route: route_id, direction_id: direction_id]
    |> Predictions.Repo.all
    |> Enum.filter_map(
      &(upcoming?(&1.time, conn.assigns[:date_time]) && departing?(&1.trip_id, stop_id)),
      (&{:predicted, Schedules.Repo.trip(&1.trip_id), &1.time})
    )

    scheduled = stop_id
    |> Schedules.Repo.schedule_for_stop(route: route_id, date: conn.assigns[:date], direction_id: direction_id)
    |> Enum.filter_map(
      &(upcoming?(&1.time, conn.assigns[:date_time]) && departing?(&1.trip.id, stop_id)),
      &{:scheduled, &1.trip, &1.time}
    )

    predicted
    |> Enum.concat(scheduled)
    |> Enum.sort_by(&(elem(&1, 2)))
    |> Enum.group_by(&(elem(&1, 1).headsign))
    |> Enum.map(fn {headsign, departures} ->
      {headsign, Enum.take(departures, 3)}
    end)
  end

  def render_commuter_departure_time(route_id, direction_id, schedule, prediction) do
    formatted_scheduled = Timex.format!(schedule.time, "{h12}:{m} {AM}")
    path = schedule_path(Site.Endpoint, :show, route_id, trip: schedule.trip.id, direction_id: direction_id)
    do_render_commuter_departure_time(path, formatted_scheduled, prediction)
  end

  @doc """
    Finds the difference between now and a time, and displays either the difference in minutes or the formatted time
    if the difference is greater than an hour.
  """
  @spec schedule_display_time(DateTime.t) :: String.t
  def schedule_display_time(time) do
    Timex.diff(time, Util.now, :minutes)
    |> do_schedule_display_time(time)
  end

  def do_schedule_display_time(diff, time) when diff > 60 or diff < -1  do
    time
    |> Timex.format!("{h12}:{m} {AM}")
  end

  def do_schedule_display_time(diff, _) do
    case diff do
      0 -> "< 1 min"
      x -> "#{x} #{Inflex.inflect("min", x)}"
    end
  end

  def predicted_icon(:predicted) do
      ~s(<i class="fa fa-rss station-schedule-icon"></i><span class="sr-only">Predicted departure time: </span>)
      |> Phoenix.HTML.raw
  end
  def predicted_icon(_), do: ""

  defp do_render_commuter_departure_time(path, formatted_scheduled, nil) do
    [link(formatted_scheduled, to: path)]
  end
  defp do_render_commuter_departure_time(path, formatted_scheduled, prediction) do
    formatted_predicted = Timex.format!(prediction.time, "{h12}:{m} {AM}")
    if formatted_predicted != formatted_scheduled do
      [content_tag(:s, formatted_scheduled), tag(:br), link(formatted_predicted, to: path)]
    else
      [link(formatted_scheduled, to: path)]
    end
  end

  defp departing?(trip, stop) do
    trip
    |> Schedules.Repo.schedule_for_trip
    |> Enum.drop_while(&(&1.stop.id != stop))
    |> (fn (schedules) -> match?([_, _ | _], schedules) end).()
  end

  defp upcoming?(time, now) do
    time
    |> Timex.diff(now, :minutes)
    |> Kernel.>=(0)
  end
end
