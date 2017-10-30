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
    content_tag :div do
      for {text, path} <- Routes.Pdf.all_pdfs_for_route(route, date) do
        text = Enum.map(text, &break_text_at_slash/1)
        url = static_url(Site.Endpoint, path)
        content_tag :div, class: "schedules-v2-pdf-link" do
          link(to: url, target: "_blank") do
            [fa("file-pdf-o"), " View PDF of ", text]
          end
        end
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
                href: stop_path(Site.Endpoint, :show, route_stop.id),
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
end
