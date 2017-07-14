defmodule Site.TripPlanController do
  use Site.Web, :controller
  alias Site.TripPlan.Query
  alias Site.TripPlan.Map, as: TripPlanMap
  alias Site.TripPlan.Alerts, as: TripPlanAlerts
  alias Site.TripPlan.RelatedLink
  alias Site.TripPlan.{ItineraryRowList, ItineraryRow}
  alias Site.PartialView.StopBubbles
  import Site.Validation, only: [validate_by_field: 2]

  plug :require_google_maps
  plug :assign_initial_map, TripPlanMap.initial_map_src()

  @type route_map :: %{optional(Routes.Route.id_t) => Routes.Route.t}
  @type route_mapper :: ((Routes.Route.id_t) -> Routes.Route.t | nil)

  def index(conn, %{"plan" => %{"date_time" => date_time} = plan}) do
    params = %{"date_string" => build_date_string(date_time), "system_date_time" => conn.assigns.date_time}
    validators = %{date_time: &validate_date/1}
    conn = assign(conn, :errors, validate_by_field(validators, params))
    if Enum.empty?(conn.assigns.errors) do
      render_plan(conn, plan)
    else
      render(conn, :index)
    end
  end
  def index(conn, _params) do
    conn
    |> assign(:errors, [])
    |> render(:index)
  end

  defp render_plan(conn, plan) do
    query = Query.from_query(plan)
    route_map = with_itineraries(query, %{}, &routes_for_query/1)
    route_mapper = &Map.get(route_map, &1)
    itinerary_row_lists = itinerary_row_lists(query, route_mapper)
    render conn,
      query: query,
      route_map: route_map,
      itinerary_maps: with_itineraries(query, [], &itinerary_maps(&1, route_mapper)),
      related_links: with_itineraries(query, [], &related_links(&1, route_mapper)),
      alerts: with_itineraries(query, [], &alerts(&1, route_mapper)),
      itinerary_row_lists: itinerary_row_lists,
      stop_bubble_params_list: stop_bubble_params(itinerary_row_lists),
      destination_stop_bubble_params_list: destination_stop_bubble_params_list(itinerary_row_lists)
  end

  @spec validate_date(map) :: :ok | String.t
  def validate_date(%{"date_string" => date_string, "system_date_time" => system_date_time}) do
    date = convert_to_date(date_string)
    case date do
      nil -> "Date is not valid."
      _ -> check_future_date(date, system_date_time)
    end
  end

  @spec convert_to_date(String.t) :: NaiveDateTime.t | nil
  def convert_to_date(date_string) do
    {result, date_time} = Timex.parse(date_string, "{YYYY}-{M}-{D}T{h24}:{m}:{s}")
    case {result, Timex.is_valid?(date_time)} do
      {:ok, true} -> date_time
      {_, _} -> nil
    end
  end

  @spec check_future_date(NaiveDateTime.t, DateTime.t) :: :ok | String.t
  def check_future_date(naive_date, system_date_time) do
    local_date_time = Timex.to_datetime(naive_date, system_date_time.time_zone)
    if Timex.after?(local_date_time, system_date_time), do: :ok, else: "The date selected has already passed."
  end

  @spec build_date_string(map) :: String.t
  defp build_date_string(%{"year" => year, "month" => month, "day" => day, "hour" => hour, "minute" => minute}) do
    "#{year}-#{month}-#{day}T#{hour}:#{String.pad_leading(minute, 2, "0")}:00"
  end
  defp build_date_string(_), do: ""

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  def itinerary_row_lists(query, route_mapper) do
    with_itineraries(query, [], &do_itinerary_row_lists(&1, route_mapper))
  end

  defp do_itinerary_row_lists(itineraries, route_mapper) do
    Enum.map(itineraries, fn itinerary -> ItineraryRowList.from_itinerary(itinerary, route_mapper: route_mapper) end)
  end

  def assign_initial_map(conn, url) do
    assign(conn, :initial_map_src, url)
  end

  defp with_itineraries(query, default, function)
  defp with_itineraries(%Query{itineraries: {:ok, itineraries}}, _default, function) do
    function.(itineraries)
  end
  defp with_itineraries(%Query{}, default, _function) do
    default
  end

  @spec routes_for_query([TripPlan.Itinerary.t]) :: route_map
  defp routes_for_query(itineraries) do
    itineraries
    |> Enum.flat_map(&TripPlan.Itinerary.route_ids/1)
    |> Enum.uniq
    |> Map.new(&{&1, Routes.Repo.get(&1)})
  end

  @spec alerts([TripPlan.Itinerary.t], route_mapper) :: [alert_list] when alert_list: [Alerts.Alert.t]
  defp alerts([], _) do
    []
  end
  defp alerts([first | _] = itineraries, route_mapper) do
    # time here is only used for sorting, so it's okay that the time might
    # not exactly match the alerts
    all_alerts = Alerts.Repo.all(first.start)
    opts = [route_by_id: route_mapper]
    for itinerary <- itineraries do
      TripPlanAlerts.filter_for_itinerary(all_alerts, itinerary, opts)
    end
  end

  defp itinerary_maps(itineraries, route_mapper) do
    Enum.map(itineraries, &TripPlanMap.itinerary_map(&1, route_mapper: route_mapper))
  end

  defp related_links(itineraries, route_mapper) do
    for itinerary <- itineraries do
      RelatedLink.links_for_itinerary(itinerary, route_by_id: route_mapper)
    end
  end

  defp stop_bubble_params(itinerary_row_lists) do
    itinerary_row_lists
    |> Enum.map(fn row_list ->
      row_list
      |> Enum.zip(Stream.concat([:terminus], Stream.repeatedly(fn -> :stop end)))
      |> Enum.map(&to_stop_bubble_params/1)
    end)
  end

  defp to_stop_bubble_params({itinerary_row, bubble_type}) do
    %StopBubbles.Params{
      bubbles: [{nil, bubble_type}],
      stop_id: elem(itinerary_row.stop, 1),
      route_id: ItineraryRow.route_id(itinerary_row),
      route_type: ItineraryRow.route_type(itinerary_row)
    }
  end

  defp destination_stop_bubble_params_list(itinerary_row_lists) do
    Enum.map(itinerary_row_lists, fn %ItineraryRowList{destination: {_, id, _}} ->
      %StopBubbles.Params{
        bubbles: [{nil, :terminus}],
        stop_number: 1, # greater than zero so last terminus
        stop_id: id,
        route_id: nil,
        route_type: nil
      }
    end)
  end
end
