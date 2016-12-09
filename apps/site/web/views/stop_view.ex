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
  def mode_summaries(:commuter_rail, name) do
    filters = mode_filters(:commuter_rail, name)
    summaries_for_filters(filters, :bus_subway) |> Enum.map(fn(summary) -> %{summary | modes: [:commuter_rail]} end)
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
  defp mode_filters(:commuter_rail, name) do
    [[mode: :commuter_rail, duration: :single_trip, reduced: nil, name: name],
     [mode: :commuter_rail, duration: :month, media: [:commuter_ticket], reduced: nil, name: name]]
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
    !origin_station?(stop)
  end

  @spec origin_station?(Stop.t) :: boolean
  def origin_station?(stop) do
    stop.id in @origin_stations
  end

  @spec fare_surcharge?(Stop.t) :: boolean
  def fare_surcharge?(stop) do
    stop.id in ["place-bbsta", "place-north", "place-sstat"]
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
  def schedule_template(:commuter_rail), do: "_commuter_schedule.html"
  def schedule_template(_), do: "_mode_schedule.html"

  @spec has_alerts?(Plug.Conn.t, Alerts.InformedEntity.t) :: boolean
  @doc "Returns true if the given route has alerts. The date is supplied by the conn."
  def has_alerts?(conn, informed_entity) do
    Alerts.Repo.all
    |> Enum.reject(&Alerts.Alert.is_notice?(&1, conn.assigns.date))
    |> Alerts.Match.match(informed_entity, conn.assigns.date)
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

  @spec upcoming_departures(%{date_time: DateTime.t, mode: Routes.Route.route_type, stop_schedule: [Schedules.Schedule.t], stop_predictions: [Predictions.Prediction.t]}, String.t, String.t, integer) :: [{:scheduled | :predicted, String.t, DateTime.t}]
  @doc "Returns the next departures for the given stop, route, and direction."
  def upcoming_departures(%{date_time: date_time, mode: mode, stop_schedule: stop_schedule, stop_predictions: stop_predictions}, stop_id, route_id, direction_id) do
    predicted =
      case route_id do
        "Green"<>line -> [] # Skip Greenline predictions
        _ -> stop_predictions
             |> route_predictions(route_id, direction_id)
             |> Enum.filter(&(upcoming?(&1.time, date_time, mode)))
             |> Enum.map(&({:predicted, Schedules.Repo.trip(&1.trip_id), &1.time}))
      end

    scheduled = stop_schedule
    |> route_schedule(route_id, direction_id)
    |> Enum.filter(&(upcoming?(&1.time, date_time, mode)))
    |> Enum.map(&{:scheduled, &1.trip, &1.time})

    predicted
    |> Enum.concat(scheduled)
    |> dedup_trips
    |> Enum.sort_by(&(elem(&1, 2)))
    |> Enum.group_by(&(elem(&1, 1).headsign))
    |> Enum.filter(fn({_k,v}) -> departing?(elem(List.first(v), 1).id, stop_id) end)
    |> Enum.map(fn {headsign, departures} ->
      {headsign, limit_departures(departures)}
    end)
  end

  @spec route_predictions([Predictions.Prediction.t], integer, integer) :: [Predictions.Prediction.t]
  defp route_predictions(predictions, route_id, direction_id) do
    predictions
    |> Enum.filter(&(&1.route_id == route_id and &1.direction_id == direction_id))
  end

  @spec route_schedule([Schedules.Schedule.t], integer, integer) :: [Schedules.Schedule.t]
  defp route_schedule(schedules, route_id, direction_id) do
    schedules
    |> Enum.filter(&(&1.route.id == route_id and &1.trip.direction_id == direction_id))
  end


  # Find the first three predicted departures to display. If there are
  # fewer than three, fill out the list with scheduled departures
  # which leave after the last predicted departure.
  defp limit_departures(departures) do
    scheduled_after_predictions = departures
    |> Enum.reverse
    |> Enum.take_while(&(match?({:scheduled, _, _}, &1)))
    |> Enum.reverse

    predictions = departures
    |> Enum.filter(&(match?({:predicted, _, _}, &1)))

    predictions
    |> Stream.concat(scheduled_after_predictions)
    |> Enum.take(3)
  end

  def render_commuter_departure_time(route_id, direction_id, schedule, prediction) do
    formatted_scheduled = Timex.format!(schedule.time, "{h12}:{m} {AM}")
    path = schedule_path(Site.Endpoint, :show, route_id, trip: schedule.trip.id, direction_id: direction_id)
    do_render_commuter_departure_time(path, formatted_scheduled, prediction)
  end

  def station_schedule_empty_msg(mode) do
    content_tag :div, "There are no upcoming #{mode |> mode_name |> String.downcase} departures until the start of tomorrow's service.", class: "station-schedules-empty station-route-row"
  end

  @doc """
    Finds the difference between now and a time, and displays either the difference in minutes or the formatted time
    if the difference is greater than an hour.
  """
  @spec schedule_display_time(DateTime.t, DateTime.t) :: String.t
  def schedule_display_time(time, now) do
    time
    |> Timex.diff(now, :minutes)
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
      ~s(<i data-toggle="tooltip" title="Real Time Service" class="fa fa-rss station-schedule-icon"></i><span class="sr-only">Predicted departure time: </span>)
      |> Phoenix.HTML.raw
  end
  def predicted_icon(_), do: ""

  @doc "URL for the embedded Google map image for the stop."
  @spec map_url(Stop.t, non_neg_integer, non_neg_integer, non_neg_integer) :: String.t
  def map_url(stop, width, height, scale) do
    opts = [
      channel: "beta_mbta_station_info",
      zoom: 16,
      scale: scale
    ] |> Keyword.merge(center_query(stop))

    GoogleMaps.static_map_url(width, height, opts)
  end

  @doc """
  Returns a map of query params to determine the center of the Google map image. If the stop has
  GPS coordinates, places a marker at its location. Otherwise, it centers the map around the stop without
  a marker.
  """
  @spec center_query(Stop.t) :: %{atom => String.t}
  def center_query(stop) do
    bus_stop? = stop.id
    |> Routes.Repo.by_stop
    |> Enum.all?(&(&1.type == 3))

    if bus_stop? do
      [markers: location(stop)]
    else
      [center: location(stop)]
    end
  end

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

  defp upcoming?(trip_time, now, mode) do
    trip_time
    |> Timex.diff(now, :minutes)
    |> do_upcoming?(now, mode)
  end

  defp do_upcoming?(diff, now, :subway) do
    # show all upcoming subway departures during early morning hours
    # without service; otherwise limit it to within 30 minutes
    diff >= 0 && (now.hour <= 5 || diff <= 30)
  end
  defp do_upcoming?(diff, _now, _mode) do
    diff >= 0
  end

  # If we have both a schedule and a prediction for a trip, prefer the predicted version.
  defp dedup_trips(departures) do
    departures
    |> Enum.reduce({%{}, []}, &dedup_trip_reducer/2)
    |> elem(1)
  end

  defp dedup_trip_reducer({:predicted, trip, _} = departure, {seen, final}) do
    {Map.put(seen, trip.id, :predicted), [departure | final]}
  end
  defp dedup_trip_reducer({:scheduled, trip, _} = departure, {seen, final} = acc) do
    case Map.get(seen, trip.id) do
      :predicted -> acc
      _ -> {Map.put(seen, trip.id, :scheduled), [departure | final]}
    end
  end
end
