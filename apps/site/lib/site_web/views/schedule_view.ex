defmodule SiteWeb.ScheduleView do
  use SiteWeb, :view

  import SiteWeb.ScheduleView.StopList
  import SiteWeb.ScheduleView.TripList
  import SiteWeb.ScheduleView.Timetable

  require Routes.Route
  alias Routes.Route
  alias Stops.Stop
  alias Site.MapHelpers
  alias SiteWeb.PartialView.SvgIconWithCircle

  defdelegate update_schedule_url(conn, opts), to: UrlHelpers, as: :update_url

  @doc """
  Given a list of schedules, returns a display of the route direction. Assumes all
  schedules have the same route and direction.
  """
  @spec display_direction(JourneyList.t) :: iodata
  def display_direction(%JourneyList{journeys: journeys}) do
    do_display_direction(journeys)
  end

  @spec do_display_direction([Journey.t]) :: iodata
  defp do_display_direction([%Journey{departure: predicted_schedule} | _]) do
    [
      Route.direction_name(
        PredictedSchedule.route(predicted_schedule),
        PredictedSchedule.direction_id(predicted_schedule)
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
      downcase_direction(direction),
      " trips."
    ]
  end
  def no_trips_message(_, _, _, direction, date) when not is_nil(direction) do
    [
      "There are no scheduled ",
      downcase_direction(direction),
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

  for direction <- ["Outbound", "Inbound",
                    "Westbound", "Eastbound",
                    "Northbound", "Southbound"] do
      defp downcase_direction(unquote(direction)), do: unquote(String.downcase(direction))
  end
  defp downcase_direction(direction) do
    # keep it the same if it's not one of our expected ones
    direction
  end

  @spec route_pdf_link([Content.RoutePdf] | nil, Route.t, Date.t) :: Phoenix.HTML.Safe.t
  def route_pdf_link(route_pdfs, route, today) do
    route_pdfs = route_pdfs || []
    all_current? = Enum.all?(route_pdfs, &Content.RoutePdf.started?(&1, today))
    content_tag :div, class: "pdf-links" do
      for pdf <- route_pdfs do
        url = static_url(SiteWeb.Endpoint, pdf.path)
        content_tag :div, class: "schedules-pdf-link" do
          link(to: url, target: "_blank") do
            text_for_route_pdf(pdf, route, today, all_current?)
          end
        end
      end
    end
  end

  @spec text_for_route_pdf(Content.RoutePdf.t, Route.t, Date.t, boolean) :: iodata
  defp text_for_route_pdf(pdf, route, today, all_current?) do
    current_or_upcoming_text = cond do
      all_current? -> ""
      Content.RoutePdf.started?(pdf, today) -> "current "
      true -> "upcoming "
    end

    pdf_name = if Content.RoutePdf.custom?(pdf) do
      pdf.link_text_override
    else
      [pretty_route_name(route), " schedule"]
    end

    effective_date_text = if Content.RoutePdf.started?(pdf, today) do
      ""
    else
      [" — effective ", pretty_date(pdf.date_start)]
    end

    [fa("file-pdf-o"), " Download PDF of ", current_or_upcoming_text, pdf_name, effective_date_text]
  end

  @spec pretty_route_name(Route.t) :: String.t
  def pretty_route_name(route) do
    route_prefix = if route.type == 3, do: "Route ", else: ""
    route_name = route.name
    |> String.replace_trailing(" Line", " line")
    |> String.replace_trailing(" Ferry", " ferry")
    |> String.replace_trailing(" Trolley", " trolley")
    |> break_text_at_slash
    route_prefix <> route_name
  end

  @spec direction_select_column_width(nil | boolean, integer) :: 0..12
  def direction_select_column_width(true, _headsign_length), do: 6
  def direction_select_column_width(_, headsign_length) when headsign_length > 20, do: 8
  def direction_select_column_width(_, _headsign_length), do: 4

  @spec fare_params(Stop.t, Stop.t) :: %{optional(:origin) => Stop.id_t, optional(:destination) => Stop.id_t}
  def fare_params(origin, destination) do
    case {origin, destination} do
      {nil, nil} -> %{}
      {origin, nil} -> %{origin: origin}
      {origin, destination} -> %{origin: origin, destination: destination}
    end
  end

  @spec render_trip_info_stops([PredictedSchedule.t], map, Keyword.t) :: [Phoenix.HTML.Safe.t]
  def render_trip_info_stops(schedule_list, assigns, opts \\ [])
  def render_trip_info_stops([], _, _) do
    []
  end
  def render_trip_info_stops(schedule_list, assigns, opts) do
    route = assigns.route
    route_name = route.name
    direction_id = assigns.direction_id
    all_alerts = assigns.all_alerts
    first? = opts[:first?] == true
    last? = opts[:last?] == true
    terminus? = first? or last?
    for predicted_schedule <- schedule_list do
      route_stop = build_route_stop_from_predicted_schedule(predicted_schedule, first?, last?)
      vehicle_tooltip = if predicted_schedule.schedule && predicted_schedule.schedule.trip do
        assigns.vehicle_tooltips[{predicted_schedule.schedule.trip.id, route_stop.id}]
      end
      render("_stop_list_row.html", %{
      bubbles: [{route_name, (if terminus?, do: :terminus, else: :stop)}],
                direction_id: direction_id,
                stop: route_stop,
                href: stop_path(SiteWeb.Endpoint, :show, route_stop.id),
                route: route,
                vehicle_tooltip: vehicle_tooltip,
                terminus?: terminus?,
                alerts: stop_alerts(predicted_schedule, all_alerts, route.id, direction_id),
                predicted_schedule: predicted_schedule,
                row_content_template: "_trip_info_stop.html"
      })
    end
  end

  @spec build_route_stop_from_predicted_schedule(PredictedSchedule.t, boolean, boolean) :: Stops.RouteStop.t
  defp build_route_stop_from_predicted_schedule(predicted_schedule, first?, last?) do
    stop = PredictedSchedule.stop(predicted_schedule)
    route = PredictedSchedule.route(predicted_schedule)
    Stops.RouteStop.build_route_stop(stop, route, first?: first?, last?: last?)
  end

  @doc "Prefix route name with route for bus lines"
  def route_header_text(%Route{type: 3, name: name} = route) do
    if Route.silver_line_rapid_transit?(route) do
      ["Silver Line ", name]
    else
      content_tag :div, class: "bus-route-sign h1--new" do
        route.name
      end
    end
  end
  def route_header_text(%Route{type: 2, name: name}), do: [clean_route_name(name)]
  def route_header_text(%Route{name: name}), do: [name]

  @spec header_class(Route.t) :: String.t
  def header_class(%Route{type: 3} = route) do
    if Route.silver_line_rapid_transit?(route) do
      do_header_class("silver-line")
    else
      do_header_class("bus")
    end
  end
  def header_class(%Route{} = route) do
    route
    |> route_to_class()
    |> do_header_class()
  end

  @spec do_header_class(String.t) :: String.t
  defp do_header_class(<<modifier::binary>>) do
    "u-bg--" <> modifier
  end

  @doc "Route sub text (long names for bus routes)"
  @spec route_header_description(Route.t) :: String.t
  def route_header_description(%Route{type: 3} = route) do
    if Route.silver_line_rapid_transit?(route) do
      ""
    else
      content_tag :h2, class: "schedule__description h2--new" do
        "Bus Route"
      end
    end
  end
  def route_header_description(_), do: ""

  def route_header_tabs(conn) do
    route = conn.assigns.route
    tab_params = conn.assigns.tab_params
    schedule_link = trip_view_path(conn, :show, route.id, tab_params)
    info_link = line_path(conn, :show, route.id, tab_params)
    timetable_link = timetable_path(conn, :show, route.id, tab_params)
    tabs = [{"trip-view", "Schedule", schedule_link},
            {"line", "Info & Maps", info_link}]
    tabs = case route.type do
        2 -> [{"timetable", "Timetable", timetable_link} | tabs]
        _ -> tabs
    end
    SiteWeb.PartialView.HeaderTabs.render_tabs(tabs, conn.assigns.tab, route_tab_class(route))
  end

  @spec route_tab_class(Route.t) :: String.t
  defp route_tab_class(%Route{type: 3} = route) do
    if Route.silver_line_rapid_transit?(route) do
      ""
    else
      "header-tab--bus"
    end
  end
  defp route_tab_class(_), do: ""
end
