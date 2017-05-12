defmodule Site.ScheduleV2View do
  use Site.Web, :view
  import Site.ScheduleV2View.StopList, only: [build_stop_list: 1, add_expand_link?: 2,
                                              stop_bubble_content: 4,
                                              view_branch_link: 3, stop_bubble_location_display: 3]

  require Routes.Route
  alias Routes.Route

  defdelegate update_schedule_url(conn, opts), to: UrlHelpers, as: :update_url

  def pretty_date(date) do
    if date == Util.service_date do
      "Today"
    else
      Timex.format!(date, "{Mshort} {D}")
    end
  end

  @doc """
  Given a list of schedules, returns a display of the route direction. Assumes all
  schedules have the same route and direction.
  """
  @spec display_direction(StopTimeList.t) :: iodata
  def display_direction(%StopTimeList{times: times}) do
    do_display_direction(times)
  end

  @spec do_display_direction([StopTime.t]) :: iodata
  defp do_display_direction([%StopTime{departure: predicted_schedule} | _]) do
    [
      direction(
        PredictedSchedule.direction_id(predicted_schedule),
        PredictedSchedule.route(predicted_schedule)
      ),
      " to"
    ]
  end
  defp do_display_direction([]), do: ""



  @doc """
  Displays the CR icon if given a non-nil vehicle location. Otherwise, displays nothing.
  """
  @spec timetable_location_display(Vehicles.Vehicle.t | nil) :: Phoenix.HTML.Safe.t
  def timetable_location_display(%Vehicles.Vehicle{}) do
    svg_icon %SvgIcon{icon: :commuter_rail, class: "icon-small", show_tooltip?: false}
  end
  def timetable_location_display(_location), do: ""

  @spec tab_selected?(tab :: String.t, current_tab :: String.t | nil) :: boolean()
  @doc """
  Given a schedule tab, and the selected tab, returns whether or not the schedule tab should be rendered as selected.
  """
  def tab_selected?(tab, tab), do: true
  def tab_selected?(_, _), do: false

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template for the selected tab."
  def template_for_tab("trip-view"), do: "_trip_view.html"
  def template_for_tab("timetable"), do: "_timetable.html"
  def template_for_tab("line"), do: "_line.html"

  @spec reverse_direction_opts(Stops.Stop.t | nil, Stops.Stop.t | nil, 0..1) :: Keyword.t
  def reverse_direction_opts(origin, destination, direction_id) do
    origin_id = if origin, do: origin.id, else: nil
    destination_id = if destination, do: destination.id, else: nil

    new_origin_id = destination_id || origin_id
    new_dest_id = destination_id && origin_id

    [trip: nil, direction_id: direction_id, destination: new_dest_id, origin: new_origin_id]
  end

  @doc """
  Returns Trip Alerts by the trip id and time from the given predicted_schedule, route and direction_id
  If no schedule is available, the prediction is used to match against alerts
  Does not return alerts for Bus routes
  """
  @spec trip_alerts(PredictedSchedule.t | nil, [Alerts.Alert.t],  Route.t, String.t) :: [Alerts.Alert.t]
  def trip_alerts(_predicted_schedule, _alerts, %Route{type: 3}, _direction_id), do: []
  def trip_alerts(predicted_schedule, alerts, route, direction_id) do
    PredictedSchedule.map_optional(predicted_schedule, [:schedule, :prediction], [], fn x ->
      Alerts.Trip.match(alerts, x.trip.id, time: x.time, route: route.id, direction_id: direction_id)
    end)
  end

  @doc """
  Matches the given alerts with the stop id and time from the given predicted_schedule, route and direction_id
  If no schedule is available, the prediction is used to match against alerts
  """
  @spec stop_alerts(PredictedSchedule.t | nil, [Alerts.Alert.t],  String.t, String.t) :: [Alerts.Alert.t]
  def stop_alerts(predicted_schedule, alerts, route_id, direction_id) do
    PredictedSchedule.map_optional(predicted_schedule, [:schedule, :prediction], [], fn x ->
      Alerts.Stop.match(alerts, x.stop.id, time: x.time, route: route_id, direction_id: direction_id)
    end)
  end

  @doc "If alerts are given, display alert icon"
  @spec display_alerts([Alerts.Alert.t]) :: Phoenix.HTML.Safe.t
  def display_alerts([]), do: raw ""
  def display_alerts(_alerts), do: svg_icon(%SvgIcon{icon: :alert, class: "icon-small"})

  @spec prediction_status_text(Predictions.Prediction.t | nil) :: iodata
  def prediction_status_text(%Predictions.Prediction{status: status, track: track}) when not is_nil(track) do
    [String.capitalize(status), " on track ", track]
  end
  def prediction_status_text(_) do
    ""
  end

  @spec prediction_time_text(Predictions.Prediction.t | nil) :: iodata
  def prediction_time_text(nil) do
    ""
  end
  def prediction_time_text(%Predictions.Prediction{time: nil}) do
    ""
  end
  def prediction_time_text(%Predictions.Prediction{time: time, departing?: true}) do
    do_prediction_time_text("Departure", time)
  end
  def prediction_time_text(%Predictions.Prediction{time: time}) do
    do_prediction_time_text("Arrival", time)
  end

  defp do_prediction_time_text(prefix, time) do
    [prefix, ": ", Timex.format!(time, "{h12}:{m} {AM}")]
  end

  @spec prediction_stop_text(String.t, Vehicles.Vehicle.t | nil, number) :: String.t
  defp prediction_stop_text(_name, nil, _route_type), do: ""
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :incoming}, route_type), do: "#{route_type_name(route_type)} is on the way to #{name}"
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :stopped}, route_type), do: "#{route_type_name(route_type)} has arrived at #{name}"
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :in_transit}, route_type), do: "#{route_type_name(route_type)} has left #{name}"

  def build_prediction_tooltip(time_text, status_text, stop_text) do
    time_tag = do_build_prediction_tooltip(time_text)
    status_tag = do_build_prediction_tooltip(status_text)
    stop_tag = do_build_prediction_tooltip(stop_text)

    :div
    |> content_tag([stop_tag, time_tag, status_tag])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  @spec do_build_prediction_tooltip(iodata) :: Phoenix.HTML.Safe.t
  defp do_build_prediction_tooltip("") do
    ""
  end
  defp do_build_prediction_tooltip(text) do
    content_tag(:p, text, class: 'prediction-tooltip')
  end

  @spec prediction_tooltip(Predictions.Prediction.t, String.t, Vehicles.Vehicle.t | nil, number) :: Phoenix.HTML.Safe.t
  def prediction_tooltip(prediction, stop_name, vehicle, route_type) do
    time_text = prediction_time_text(prediction)
    status_text = prediction_status_text(prediction)
    stop_text = prediction_stop_text(stop_name, vehicle, route_type)

    build_prediction_tooltip(time_text, status_text, stop_text)
  end

  @spec prediction_for_vehicle_location(Plug.Conn.t, String.t, String.t) :: Predictions.Prediction.t
  def prediction_for_vehicle_location(%{assigns: %{vehicle_predictions: vehicle_predictions}}, stop_id, trip_id) do
    vehicle_predictions
    |> Enum.find(fn prediction -> prediction.stop.id == stop_id && prediction.trip.id == trip_id end)
  end
  def prediction_for_vehicle_location(conn, _stop_id, _trip_id) do
    conn
  end

  @doc """
  Returns vehicle frequency for the frequency table, either "Every X minutes" or "No service between these hours".
  """
  @spec frequency_times(boolean, Schedules.Frequency.t) :: Phoenix.HTML.Safe.t
  def frequency_times(false, _), do: content_tag :span, "No service between these hours"
  def frequency_times(true, frequency) do
    content_tag :span do
      [
        "Every ",
        TimeGroup.display_frequency_range(frequency),
        content_tag(:span, " minutes", class: "sr-only"),
        content_tag(:span, " mins", aria_hidden: true)
      ]
    end
  end

  @spec frequency_block_name(Schedules.Frequency.t) :: String.t
  defp frequency_block_name(%Schedules.Frequency{time_block: :am_rush}), do: "OPEN - 9:00AM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :midday}), do: "9:00AM - 3:30PM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :pm_rush}), do: "3:30PM - 6:30PM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :evening}), do: "6:30PM - 8:00PM"
  defp frequency_block_name(%Schedules.Frequency{time_block: :late_night}), do: "8:00PM - CLOSE"

  @doc """
  The first departure will be shown if it is the AM rush timeblock
  The last departure will be shown if it is the Late Night time block
  Otherwise, nothing is shown
  """
  @spec display_frequency_departure(TimeGroup.time_block, DateTime.t | nil, DateTime.t | nil) :: Phoenix.HTML.Safe.t
  def display_frequency_departure(:am_rush, first_departure, _last_departure) when not is_nil(first_departure) do
    content_tag :div, class: "schedule-v2-frequency-time" do
      "First Departure at #{format_schedule_time(first_departure)}"
    end
  end
  def display_frequency_departure(:late_night, _first_departure, last_departure) when not is_nil(last_departure) do
    content_tag :div, class: "schedule-v2-frequency-time" do
      "Last Departure at #{format_schedule_time(last_departure)}"
    end
  end
  def display_frequency_departure(_time_block, _first, _last), do: nil

  @doc """
  Returns the suffix to be shown in the stop selector.
  """
  @spec stop_selector_suffix(Plug.Conn.t, Stops.Stop.id_t) :: iodata
  def stop_selector_suffix(%Plug.Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, stop_id) do
    if zone = conn.assigns.zone_map[stop_id] do
      ["Zone ", zone]
    else
      ""
    end
  end
  def stop_selector_suffix(%Plug.Conn{assigns: %{route: %Routes.Route{id: "Green"}}} = conn, stop_id) do
    GreenLine.branch_ids()
    |> Enum.flat_map(fn route_id ->
      if GreenLine.stop_on_route?(stop_id, route_id, conn.assigns.stops_on_routes) do
        [display_branch_name(route_id)]
      else
        []
      end
    end)
    |> Enum.join(",")
  end
  def stop_selector_suffix(_conn, _stop_id) do
    ""
  end

  @doc """
  Pulls out the branch name of a Green Line route ID.
  """
  @spec display_branch_name(Routes.Route.id_t) :: String.t | nil
  def display_branch_name(<<"Green-", branch :: binary>>), do: branch
  def display_branch_name(_), do: nil

  @doc """
  The message to show when there are no trips for the given parameters.
  Expects either an error, two stops, or a direction.
  """
  @spec no_trips_message(any, Stops.Stop.t | nil, Stops.Stop.t | nil, String.t | nil, Date.t) :: iodata
  def no_trips_message([%{code: "no_service"} = error| _], _, _, _, date) do
    [
      format_full_date(date),
      " is not part of the ",
      rating_name(error),
      " schedule."
    ]
  end
  def no_trips_message(_, %Stops.Stop{name: origin_name}, %Stops.Stop{name: destination_name}, _, date) do
    [
      "There are no scheduled trips between ",
      origin_name,
      " and ",
      destination_name,
      " on ",
      format_full_date(date),
      "."
    ]
  end
  def no_trips_message(_, _, _, direction, date) when not is_nil(direction) do
    [
      "There are no scheduled ",
      String.downcase(direction),
      " trips on ",
      format_full_date(date),
      "."
    ]
  end
  def no_trips_message(_, _, _, _, _), do: "There are no scheduled trips."

  defp rating_name(%{meta: %{"version" => version}}) do
    version
    |> String.split(" ", parts: 2)
    |> List.first
  end

  @spec clear_selector_link(map()) :: Phoenix.HTML.Safe.t
  def clear_selector_link(%{clearable?: true, selected: selected} = assigns)
  when not is_nil(selected) do
    link to: update_url(assigns.conn, [{assigns.query_key, nil}]) do
      [
        "(clear",
        content_tag(:span, [" ", assigns.placeholder_text], class: "sr-only"),
        ")"
      ]
    end
  end
  def clear_selector_link(_assigns) do
    ""
  end

  @doc """
  Displays a schedule period.
  """
  @spec schedule_period(atom) :: String.t
  def schedule_period(:week), do: "Monday to Friday"
  def schedule_period(period) do
    period
    |> Atom.to_string
    |> String.capitalize
  end

  @spec stop_name_link_with_alerts(String.t, String.t, [Alerts.Alert.t]) :: Phoenix.HTML.Safe.t
  def stop_name_link_with_alerts(name, url, []) do
    link to: url do
      name
      |> Site.ViewHelpers.break_text_at_slash
    end
  end
  def stop_name_link_with_alerts(name, url, alerts) do
    link to: url do
      name
      |> Site.ViewHelpers.break_text_at_slash
      |> add_icon_to_stop_name(alerts)
    end
  end

  defp add_icon_to_stop_name(stop_name, alerts) do
    content_tag :span, class: "name-with-icon" do
      stop_name
      |> String.split(" ")
      |> add_icon_to_string(alerts)
    end
  end

  defp add_icon_to_string([word | []], alerts) do
    content_tag :span, class: "inline-block" do
      [word, display_alerts(alerts)]
    end
  end
  defp add_icon_to_string([word | rest], alerts) do
    [word, " ", add_icon_to_string(rest, alerts)]
  end

  @spec display_map_link?(integer) :: boolean
  def display_map_link?(type), do: type == 4 # only show for ferry

  @spec route_pdf_link(Route.t, Date.t) :: Phoenix.HTML.Safe.t
  def route_pdf_link(%Route{} = route, %Date{} = date) do
    route_suffix = if route.type == 2, do: " line", else: ""
    route_name = route
    |> route_header_text()
    |> Enum.map(&lowercase_line/1)
    |> Enum.map(&lowercase_ferry/1)
    case Routes.Pdf.dated_urls(route, date) do
      [] ->
        []
      [{previous_date, _}] ->
        do_pdf_link(route, previous_date, [route_name, route_suffix, " paper schedule"])
      [{previous_date, _}, {next_date, _} | _] ->
        content_tag :div, class: "trip-schedules-pdf-multiple" do
          [
            do_pdf_link(route, previous_date, [route_name, route_suffix, " paper schedule"]),
            do_pdf_link(route, next_date, ["upcoming schedule — effective ", Timex.format!(next_date, "{Mshort} {D}")]),
            south_station_commuter_rail(route)
          ]
        end
    end
  end

  @spec south_station_commuter_rail(Routes.Route.t) :: Phoenix.HTML.Safe.t
  def south_station_commuter_rail(route) do
    pdf_path = Routes.Pdf.south_station_back_bay_pdf(route)
    if pdf_path do
      link(to: pdf_path, target: "_blank") do
        [
          fa("file-pdf-o"),
          " View PDF of Back Bay to South Station schedule",
        ]
      end
    else
      []
    end
  end

  defp lowercase_line(input) do
    String.replace_trailing(input, " Line", " line")
  end

  defp lowercase_ferry(input) do
    String.replace_trailing(input, " Ferry", " ferry")
  end

  defp do_pdf_link(route, date, link_iodata) do
    iso_date = Date.to_iso8601(date)
    link(to: route_pdf_path(Site.Endpoint, :pdf, route, date: iso_date), target: "_blank") do
      [
        fa("file-pdf-o"),
        " View PDF of ",
        link_iodata
      ]
    end
  end

  @doc """
  Returns a link to expand or collapse the trip list. No link is shown
  if there are no additional trips
  """
  @spec trip_expansion_link(:none | :collapsed | :expanded, Date.t, Plug.Conn.t) :: Phoenix.HTML.Safe.t | nil
  def trip_expansion_link(:none, _date, _conn) do
    nil
  end
  def trip_expansion_link(:collapsed, date, conn) do
    date_string = date |> pretty_date |> String.downcase
    link to: update_url(conn, show_all_trips: true) <> "#trip-list", class: "trip-list-v2-row trip-list-v2-footer" do
      "Show all trips for #{date_string}"
    end
  end
  def trip_expansion_link(:expanded, _date, conn) do
    link to: update_url(conn, show_all_trips: false) <> "#trip-list", class: "trip-list-v2-row trip-list-v2-footer" do
      "Show upcoming trips only"
    end
  end

  @spec direction_tooltip(0..4) :: String.t
  def direction_tooltip(route_type) when route_type in [2,4] do
    :div
    |> content_tag([content_tag(:p,
      "Schedule times are shown for the direction displayed in the box below. Click on the box to change direction. Inbound trips go to Boston, and outbound trips leave from there.",
      class: 'schedule-tooltip')])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end
  def direction_tooltip(_route_type) do
    :div
    |> content_tag([content_tag(:p,
      "Schedule times are shown for the direction displayed in the box below. Click on the box to change direction.",
      class: 'schedule-tooltip')])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  @spec date_tooltip() :: String.t
  def date_tooltip do
    :div
    |> content_tag([content_tag(:p,
      "Select a date to view that day’s schedule. Weekdays, Saturdays, and Sundays usually have different schedules.",
      class: 'schedule-tooltip')])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  @spec direction_select_column_width(nil | boolean, integer) :: String.t
  def direction_select_column_width(true, _headsign_length), do: "6"
  def direction_select_column_width(_, headsign_length) when headsign_length > 20, do: "8"
  def direction_select_column_width(_, _headsign_length), do: "4"
end
