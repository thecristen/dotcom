defmodule Site.StopView do
  use Site.Web, :view

  alias Stops.Stop
  alias Fares.RetailLocations.Location
  alias Schedules.Schedule
  alias Schedules.Trip
  alias Routes.Route
  alias Predictions.Prediction

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
    |> Enum.map(&(if &1.name == "Mattapan Trolley", do: %{&1 | name: "Red Line"}, else: &1))
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
    content_tag(:span, "#{name} is an accessible station.")
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

  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("info"), do: "_info.html"
  def template_for_tab(_tab), do: "_schedule.html"

  @spec tab_selected?(tab :: String.t, current_tab :: String.t | nil) :: boolean()
  @doc """
  Given a station tab, and the selected tab, returns whether or not the station tab should be rendered as selected.
  """
  def tab_selected?(tab, tab), do: true
  def tab_selected?("schedule", nil), do: true
  def tab_selected?(_, _), do: false

  @spec schedule_template(Routes.Route.route_type) :: String.t
  @doc "Returns the template to render schedules for the given mode."
  def schedule_template(:commuter_rail), do: "_commuter_schedule.html"
  def schedule_template(_), do: "_mode_schedule.html"

  @spec has_alerts?([Alerts.Alert.t], Date.t, Alerts.InformedEntity.t) :: boolean
  @doc "Returns true if the given route has alerts. The date is supplied by the conn."
  def has_alerts?(all_alerts, date, informed_entity) do
    all_alerts
    |> Enum.reject(&Alerts.Alert.is_notice?(&1, date))
    |> Alerts.Match.match(informed_entity, date)
    |> Enum.empty?
    |> Kernel.not
  end

  @spec upcoming_commuter_departures(Plug.Conn.t, integer, integer) :: Schedule.t | nil
  @doc "Returns the next departure for the given stop, CR line, and direction."
  def upcoming_commuter_departures(conn, route, direction_id) do
    conn.assigns.stop_schedule
    |> Enum.reject(&(&1.pickup_type == 1))
    |> route_schedule(route, direction_id)
    |> Enum.find(&(Timex.after?(&1.time, conn.assigns[:date_time])))
  end

  @spec upcoming_departures(%{date_time: DateTime.t, mode: Route.route_type, stop_schedule: [Schedule.t], stop_predictions: [Prediction.t]}, String.t, integer, integer) :: [{String.t, [{:scheduled | :predicted, String.t, DateTime.t}]}]
  @doc "Returns the next departures for the given stop, route, and direction."
  def upcoming_departures(%{date_time: date_time, mode: mode, stop_schedule: stop_schedule, stop_predictions: stop_predictions}, stop_id, route_id, direction_id) do
    predicted =
      case route_id do
        "Green"<>_line -> [] # Skip Greenline predictions
        _ -> stop_predictions
        |> route_predictions(route_id, direction_id)
        |> Enum.filter_map(&(upcoming?(&1.time, date_time, mode)), &({:predicted, &1.trip, &1.time}))
      end

    scheduled = stop_schedule
    |> route_schedule(route_id, direction_id)
    |> Enum.reject(&(&1.pickup_type == 1))
    |> Enum.filter_map(&(upcoming?(&1.time, date_time, mode)),&{:scheduled, &1.trip, &1.time})

    predicted
    |> Enum.concat(scheduled)
    |> dedup_trips
    |> Enum.sort_by(&(elem(&1, 2)))
    |> Enum.group_by(&(elem(&1, 1).headsign))
    |> filter_more_stops(stop_id)
    |> Enum.map(&format_groups(&1))
  end

  @spec filter_more_stops(%{String.t => [{:scheduled | :predicted, Trip.t, DateTime.t}]}, String.t) :: [{String.t, [{:scheduled | :predicted, Trip.t, DateTime.t}]}]
  defp filter_more_stops(headsign_trip_map, stop_id) do
    # get the first trip IDs for the predictions
    prediction_trips = headsign_trip_map
    |> Enum.flat_map(fn
      {_, [{:predicted, trip, _} | _]} -> [trip.id]
      _ -> []
    end)
    # build a map of trip ID -> boolean, where the boolean is true if there
    # are more stops on the trip after our selected stop_id
    departing_map = prediction_trips
    |> Enum.join(",")
    |> Schedules.Repo.schedule_for_trip
    |> Enum.group_by(& &1.trip.id)
    |> Map.new(fn {trip_id, schedules} ->
      departing? = schedules
      |> Enum.drop_while(& &1.stop.id != stop_id)
      |> two_or_more?
      {trip_id, departing?}
    end)
    # filter out predictions that don't have a stop afterwards
    headsign_trip_map
    |> Enum.filter(fn
      {_, [{:predicted, trip, _} | _]} -> departing_map[trip.id]
      _ -> true
    end)
  end

  defp two_or_more?([_, _ | _]), do: true
  defp two_or_more?(list) when is_list(list), do: false

  @spec format_groups({String.t, [{:scheduled | :predicted, String.t, DateTime.t}]}) :: {String.t, [{:scheduled | :predicted, String.t, DateTime.t}]}
  def format_groups({headsign, departures}) do
    {headsign, limit_departures(departures)}
  end

  @spec route_predictions([Prediction.t], integer, integer) :: [Prediction.t]
  defp route_predictions(predictions, route_id, direction_id) do
    predictions
    |> Enum.filter(&(&1.route.id == route_id and &1.direction_id == direction_id && &1.time))
  end

  @spec route_schedule([Schedule.t], integer, integer) :: [Schedule.t]
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

  @spec formatted_time(DateTime.t) :: String.t
  defp formatted_time(time), do: Timex.format!(time, "{h12}:{m} {AM}")

  @spec commuter_prediction([Prediction.t], String.t) :: Prediction.t | nil
  def commuter_prediction(stop_predictions, trip_id) do
    Enum.find(
      stop_predictions,
      &match?(%Prediction{trip: %Trip{id: ^trip_id}}, &1)
    )
  end

  def station_schedule_empty_msg(mode) do
    content_tag :div, class: "station-schedules-empty station-route-row" do
      [
        "There are no upcoming ",
        mode |> mode_name |> String.downcase,
        " departures until the start of the next day's service."
      ]
    end
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

  def do_schedule_display_time(diff, time) when diff > 60 or diff < -1, do: formatted_time(time)

  def do_schedule_display_time(diff, _) do
    case diff do
      0 -> "< 1 min"
      x -> "#{x} #{Inflex.inflect("min", x)}"
    end
  end

  def predicted_icon(:predicted) do
      ~s(<i data-toggle="tooltip" title="Real-time Information" class="fa fa-rss station-schedule-icon"></i><span class="sr-only">Predicted departure time: </span>)
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
  Returns a map of query params to determine the center of the Google map image. If the stop is a station,
  it will have and icon in google maps and does not require a marker. Otherwise, the stop requires a marker.
  """
  @spec center_query(Stop.t) :: [markers: String.t] | [center: String.t]
  def center_query(stop) do
    if stop.station? do
      [center: location(stop)]
    else
      [markers: location(stop)]
    end
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

  defp dedup_trip_reducer({:predicted, nil, _}, acc) do
    # invalid trip IDs aren't fetched from the API and return nil instead
    acc
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

  @spec clean_city(String.t) :: String.t
  defp clean_city(city) do
    city = city |> String.split("/") |> List.first
    "#{city}, MA"
  end

  @doc "Returns the url for a map showing directions from a stop to a retail location."
  @spec retail_location_directions_link(Location.t, Stop.t) :: Phoenix.HTML.Safe.t
  def retail_location_directions_link(%Location{latitude: retail_lat, longitude: retail_lng}, %Stop{latitude: stop_lat, longitude: stop_lng}) do
    href = GoogleMaps.direction_map_url({stop_lat, stop_lng}, {retail_lat, retail_lng})
    content_tag :a, ["View on map ", fa("arrow-right")], href: href, class: "no-wrap"
  end

  @doc "Creates the name to be used for station info tab"
  @spec info_tab_name([Routes.Group.t]) :: String.t
  def info_tab_name([bus: _]) do
    "Stop Info"
  end
  def info_tab_name(_) do
    "Station Info"
  end
end
