defmodule Site.ScheduleV2View do
  use Site.Web, :view

  import Site.ScheduleV2View.StopList
  import Site.ScheduleV2View.TripList
  import Site.ScheduleV2View.Timetable

  require Routes.Route
  alias Routes.Route
  alias Stops.Stop
  alias Site.MapHelpers

  defdelegate update_schedule_url(conn, opts), to: UrlHelpers, as: :update_url

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

  @spec direction_select_column_width(nil | boolean, integer) :: String.t
  def direction_select_column_width(true, _headsign_length), do: "6"
  def direction_select_column_width(_, headsign_length) when headsign_length > 20, do: "8"
  def direction_select_column_width(_, _headsign_length), do: "4"

  @spec fare_params(Stop.t, Stop.t) :: %{optional(:origin) => Stop.id_t, optional(:destination) => Stop.id_t}
  def fare_params(origin, destination) do
    case {origin, destination} do
      {nil, nil} -> %{}
      {origin, nil} -> %{origin: origin}
      {origin, destination} -> %{origin: origin, destination: destination}
    end
  end

  @spec render_trip_info_stops([{{PredictedSchedule.t, boolean}, non_neg_integer}], map) :: [Phoenix.HTML.Safe.t]
  def render_trip_info_stops(stop_list, assigns) do
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
                is_expand_link?: idx == Enum.count(stop_list) - 1
      })
    end
  end
end
