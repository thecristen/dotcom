defmodule Site.ScheduleV2View do
  use Site.Web, :view
  import Site.ScheduleV2View.StopList, only: [schedule_link_direction_id: 3,
                                              view_branch_link: 3,
                                              stop_bubble_row_params: 2,
                                              chunk_branches: 1,
                                              separate_collapsible_rows: 2,
                                              merge_rows: 2
                                             ]

  require Routes.Route
  alias Routes.Route
  alias Stops.Stop
  alias Plug.Conn
  alias Site.MapHelpers

  defdelegate update_schedule_url(conn, opts), to: UrlHelpers, as: :update_url

  def pretty_date(date, format \\ "{Mshort} {D}") do
    if date == Util.service_date do
      "today"
    else
      Timex.format!(date, format)
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
  defp frequency_block_name(%Schedules.Frequency{time_block: :am_rush}), do: "OPEN - 9:00A"
  defp frequency_block_name(%Schedules.Frequency{time_block: :midday}), do: "9:00A - 3:30P"
  defp frequency_block_name(%Schedules.Frequency{time_block: :pm_rush}), do: "3:30P - 6:30P"
  defp frequency_block_name(%Schedules.Frequency{time_block: :evening}), do: "6:30P - 8:00P"
  defp frequency_block_name(%Schedules.Frequency{time_block: :late_night}), do: "8:00P - CLOSE"

  @doc """
  Formats a Schedules.Departures.t to a human-readable time range.
  """
  @spec display_departure_range(Schedules.Departures.t) :: iodata
  def display_departure_range(%Schedules.Departures{first_departure: nil, last_departure: nil}) do
    "No Service"
  end
  def display_departure_range(%Schedules.Departures{} = departures) do
    [
      format_schedule_time(departures.first_departure),
      "-",
      format_schedule_time(departures.last_departure)
    ]
  end

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
  def no_trips_message(_, _, _, direction, nil) when not is_nil(direction) do
    [
      "There are no scheduled ",
      String.downcase(direction),
      " trips."
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

  @doc "display stop feature as an icon"
  @spec stop_feature_icon(Stops.Repo.stop_feature) :: Phoenix.HTML.Safe.t
  def stop_feature_icon(:parking_lot), do: svg_icon(%SvgIcon{icon: :parking_lot})
  def stop_feature_icon(feature), do: svg_icon_with_circle(%SvgIconWithCircle{icon: feature})

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
        content_tag :div do
          [
            do_pdf_link(route, previous_date, [route_name, route_suffix, " paper schedule"]),
            lowell_weekend_shuttle_pdf(route, date),
            south_station_commuter_rail(route)
          ]
        end
      [{previous_date, _}, {next_date, _} | _] ->
        content_tag :div do
          [
            do_pdf_link(route, previous_date, [route_name, route_suffix, " paper schedule"]),
            do_pdf_link(route, next_date, ["upcoming schedule — effective ", Timex.format!(next_date, "{Mshort} {D}")]),
            lowell_weekend_shuttle_pdf(route, date),
            south_station_commuter_rail(route)
          ]
        end
    end
  end

  @spec south_station_commuter_rail(Routes.Route.t) :: Phoenix.HTML.Safe.t
  def south_station_commuter_rail(route) do
    pdf_path = Routes.Pdf.south_station_back_bay_pdf(route)
    if pdf_path do
      content_tag :div, class: "schedules-v2-pdf-link" do
        link(to: pdf_path, target: "_blank") do
          [
            fa("file-pdf-o"),
            " View PDF of Back Bay to South Station schedule",
          ]
        end
      end
    else
      []
    end
  end

  # Remove once this ends on Oct 1 -- Sky, Aug 4, 2017
  @spec lowell_weekend_shuttle_pdf(Routes.Route.t, Date.t) :: Phoenix.HTML.Safe.t
  def lowell_weekend_shuttle_pdf(%{id: "CR-Lowell"}, date) do
    if Date.compare(date, ~D[2017-10-02]) == :lt do
      content_tag :div, class: "schedules-v2-pdf-link" do
        link(to: "http://mbta.com/uploadedfiles/Riding_the_T/Landing_Pages/MBTA_Diversion_8.5x11_Lowell_Flyer_WEB.pdf", target: "_blank") do
          [
            fa("file-pdf-o"),
            " View PDF of Lowell line weekend shuttle schedule",
          ]
        end
      end
    else
      []
    end
  end
  def lowell_weekend_shuttle_pdf(_, _) do
    []
  end

  defp lowercase_line(input) do
    String.replace_trailing(input, " Line", " line")
  end

  defp lowercase_ferry(input) do
    String.replace_trailing(input, " Ferry", " ferry")
  end

  defp do_pdf_link(route, date, link_iodata) do
    iso_date = Date.to_iso8601(date)
    content_tag :div, class: "schedules-v2-pdf-link" do
      link(to: route_pdf_path(Site.Endpoint, :pdf, route, date: iso_date), target: "_blank") do
        [
          fa("file-pdf-o"),
          " View PDF of ",
          link_iodata
        ]
      end
    end
  end

  @doc """
  Returns a link to expand or collapse the trip list. No link is shown
  if there are no additional trips
  """
  @spec trip_expansion_link(:none | :collapsed | :expanded, Date.t, Conn.t) :: Phoenix.HTML.safe | nil
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

  @spec trip_link(Conn.t, TripInfo.t, boolean, String.t) :: String.t
  def trip_link(conn, trip_info, trip_chosen?, trip_id) do
    if TripInfo.is_current_trip?(trip_info, trip_id) && trip_chosen? do
      update_url(conn, trip: "") <> "#" <> trip_id
    else
      update_url(conn, trip: trip_id) <> "#" <> trip_id
    end
  end

  @spec fare_params(Stop.t, Stop.t) :: %{optional(:origin) => Stop.id_t, optional(:destination) => Stop.id_t}
  def fare_params(origin, destination) do
    case {origin, destination} do
      {nil, nil} -> %{}
      {origin, nil} -> %{origin: origin}
      {origin, destination} -> %{origin: origin, destination: destination}
    end
  end

  @spec render_trip_info_stops([{{PredictedSchedule.t, boolean}, non_neg_integer}], map, atom | nil) :: [Phoenix.HTML.Safe.t]
  def render_trip_info_stops(stop_list, assigns, collapse \\ nil) do
    for {{predicted_schedule, is_terminus?}, idx} <- stop_list do
      stop = Stops.RouteStop.build_route_stop({{PredictedSchedule.stop(predicted_schedule), is_terminus?}, idx},
                                                                                                    nil, assigns.route)
      vehicle_tooltip = if predicted_schedule.schedule && predicted_schedule.schedule.trip do
        assigns.vehicle_tooltips[{predicted_schedule.schedule.trip.id, stop.id}]
      else
        nil
      end
      render("_stop_list_row.html", %{
      bubbles: [{assigns.trip_info.route.name, (if is_terminus?, do: :terminus, else: :stop)}],
                direction_id: assigns.direction_id,
                stop: stop,
                href: stop_path(assigns.conn, :show, stop.id),
                route: assigns.trip_info.route,
                vehicle_tooltip: vehicle_tooltip,
                terminus?: is_terminus?,
                alerts: stop_alerts(predicted_schedule, assigns.all_alerts, assigns.route.id, assigns.direction_id),
                predicted_schedule: predicted_schedule,
                row_content_template: "_trip_info_stop.html",
                is_expand_link?: idx == Enum.count(stop_list) - 1 and collapse == :collapse
      })
    end
  end
end
