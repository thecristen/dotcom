defmodule Site.ScheduleV2View do
  use Site.Web, :view

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
  Given a Vehicle and a route, returns an icon for the route. Given nil, returns nothing. Adds a
  class to indicate that the vehicle is at a trip endpoint if the third parameter is true.
  """
  @spec stop_bubble_location_display(boolean, integer, boolean) :: Phoenix.HTML.Safe.t
  def stop_bubble_location_display(vehicle?, route_type, terminus?)
  def stop_bubble_location_display(true, route_type, true) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Routes.Route.type_atom(route_type), class: "icon-inverse", show_tooltip?: false})
  end
  def stop_bubble_location_display(true, route_type, false) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Routes.Route.type_atom(route_type), class: "icon-boring", show_tooltip?: false})
  end
  def stop_bubble_location_display(false, _route_type, true) do
    stop_bubble_icon(:terminus)
  end
  def stop_bubble_location_display(false, _, false) do
    stop_bubble_icon(:stop)
  end

  defp stop_bubble_icon(class) do
    content_tag :svg, viewBox: "0 0 42 42", class: "icon stop-bubble-#{class}" do
      tag :circle, r: 20, cx: 20, cy: 20, transform: "translate(2,2)"
    end
  end

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
  defp prediction_stop_text(name, %Vehicles.Vehicle{status: :incoming}, route_type), do: "#{route_type_name(route_type)} is entering #{name}"
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

  @spec prediction_trip_information(TripInfo.t) :: Phoenix.HTML.Safe.t
  def prediction_trip_information(%{sections: sections, route: route}, vehicle_locations) do
    prediction_information = Enum.find_value sections, fn section ->
      Enum.find_value section, fn item ->
        case item.schedule do
          nil ->
            false
          _ ->
            case item.schedule.trip do
              nil ->
                false
              _ ->
                vehicle = vehicle_locations[{item.schedule.trip.id, item.schedule.stop.id}]
                prediction_text = prediction_stop_text(item.schedule.stop.name, vehicle, route.type)
                case prediction_text do
                  "" ->
                    false
                  _ ->
                    prediction_text
                end
            end
        end
      end
    end
    case prediction_information do
      nil ->
        ""
      _ ->
        content_tag(:div, [prediction_information, "."], class: "route-status")
    end
  end
  def prediction_trip_information(_), do: ""

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
  Expects either two stops, or a direction.
  """
  @spec no_trips_message(Stops.Stop.t | nil, Stops.Stop.t | nil, String.t | nil, Date.t) :: Phoenix.HTML.Safe.t
  def no_trips_message(%Stops.Stop{name: origin_name}, %Stops.Stop{name: destination_name}, _, date) do
    {
      :safe, [
        "There are no scheduled trips between ",
        origin_name,
        " and ",
        destination_name,
        " on ",
        format_full_date(date),
        "."
      ]
    }
  end
  def no_trips_message(_, _, direction, date) when not is_nil(direction) do
    {
      :safe, [
        "There are no scheduled ",
        String.downcase(direction),
        " trips on ",
        format_full_date(date),
        "."
      ]
    }
  end
  def no_trips_message(_, _, _, _), do: {:safe, ["There are no scheduled trips."]}

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
  Returns a row for a given stop with all featured icons
  """
  @spec route_row(Plug.Conn.t, Stops.Stop.t, [atom], boolean) :: Phoenix.HTML.Safe.t
  def route_row(conn, stop, stop_features, is_terminus?) do
    content_tag :div, class: "route-stop" do
      [
        stop_bubble(conn.assigns.route.type, is_terminus?),
        stop_name_and_icons(conn, stop, stop_features)
      ]
    end
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

  # Displays the bubble for the line
  @spec stop_bubble(integer, boolean) :: Phoenix.HTML.Safe.t
  defp stop_bubble(route_type, is_terminus?) do
    content_tag :div, class: "stop-bubble" do
      Site.ScheduleV2View.stop_bubble_location_display(false, route_type, is_terminus?)
    end
  end

  # Displays the stop name and associated icons and zone
  @spec stop_name_and_icons(Plug.Conn.t, Stops.Stop.t, [atom]) :: Phoenix.HTML.Safe.t
  defp stop_name_and_icons(conn, stop, stop_features) do
    content_tag :div, class: "route-stop-name-icons" do
      [
        content_tag(:div, [class: "name-and-zone"], do: [
          link(break_text_at_slash(stop.name), to: stop_path(conn, :show, stop.id)),
          zone(conn.assigns[:zones], stop)
        ]),
        content_tag(:div, [class: "route-icons"], do: Enum.map(stop_features, &svg_icon_with_circle(%SvgIconWithCircle{icon: &1})))
      ]
    end
  end

  # Displays the zone
  @spec zone(map | nil, Stops.Stop.t) :: Phoenix.HTML.Safe.t
  defp zone(nil, _stop), do: ""
  defp zone(zones, stop) do
    content_tag :div, class: "zone" do
      ["Zone "<>zones[stop.id]]
    end
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

  @doc """
  Link to hide a Green/Red line branch.
  """
  @spec hide_branch_link(Plug.Conn.t, String.t) :: Phoenix.HTML.Safe.t
  def hide_branch_link(conn, branch_name) do
    do_branch_link(conn, nil, branch_name, :hide)
  end

  @doc """
  Link to view a Green/Red line branch.
  """
  @spec view_branch_link(Plug.Conn.t, String.t | nil, String.t) :: Phoenix.HTML.Safe.t
  def view_branch_link(conn, expanded, branch_name) do
    do_branch_link(conn, expanded, branch_name, :view)
  end

  @spec do_branch_link(Plug.Conn.t, String.t | nil, String.t, :hide | :view) :: Phoenix.HTML.Safe.t
  defp do_branch_link(conn, expanded, branch_name, action) do
    {action_text, caret} = case action do
                             :hide -> {"Hide ", "up"}
                             :view -> {"View ", "down"}
                           end
    link to: update_url(conn, expanded: expanded), class: "branch-link" do
      [content_tag(:span, action_text, class: "hidden-sm-down"), branch_name, " Branch ", fa("caret-#{caret}")]
    end
  end

  @doc """
  Inline SVG for a Green Line bubble with the branch.
  """
  @spec green_line_bubble(Routes.Route.id_t, atom) :: Phoenix.HTML.Safe.t
  def green_line_bubble(<<"Green-", branch :: binary>>, stop_or_terminus) do
    {div_class, svg_class} = case stop_or_terminus do
                               :stop -> {"", "stop-bubble-stop"}
                               :westbound_terminus -> {"westbound-terminus", "stop-bubble-terminus"}
                               :eastbound_terminus -> {"eastbound-terminus", "stop-bubble-terminus"}
                             end
    content_tag(:div, class: "stop-bubble green-line-bubble #{div_class}") do
      content_tag :svg, viewBox: "0 0 42 42", class: "icon icon-green-branch-bubble #{svg_class}" do
        [
          content_tag(:circle, "", r: 20, cx: 20, cy: 20, transform: "translate(2,2)"),
          content_tag(:text, branch, font_size: 24, x: 14, y: 30)
        ]
      end
    end
  end

  @doc """
  Whether or not to show the line as a solid line or a dashed/collapsed line.
  """
  @spec display_collapsed?(
    String.t | nil,
    String.t,
    {:expand, String.t, String.t} | Stops.Stop.t,
    atom,
    String.t | nil,
    GreenLine.stop_routes_pair) :: boolean
  def display_collapsed?(expanded, route_for_line, next, line_status, branch_to_expand, stops_on_routes) do
    cond do
      line_status == :line -> true
      route_for_line == branch_to_expand && branch_to_expand != expanded -> true
      match?({:expand, _, ^expanded}, next) -> false
      match?({:expand, _, _}, next) -> true
      !GreenLine.stop_on_route?(next.id, route_for_line, stops_on_routes) -> true
      true -> false
    end
  end
end
