defmodule SiteWeb.TripPlanController do
  use SiteWeb, :controller
  alias Site.TripPlan.{Query, RelatedLink, ItineraryRow, ItineraryRowList}
  alias Site.TripPlan.Map, as: TripPlanMap
  alias TripPlan.Itinerary
  alias GoogleMaps.{MapData, MapData.Marker}
  alias TripPlan.NamedPosition

  plug(:require_google_maps)
  plug(:assign_initial_map)
  plug(:breadcrumbs)
  plug(:modes)
  plug(:optimize_for)

  @type route_map :: %{optional(Routes.Route.id_t()) => Routes.Route.t()}
  @type route_mapper :: (Routes.Route.id_t() -> Routes.Route.t() | nil)

  def index(conn, %{"plan" => %{"date_time" => _dt, "to" => _to, "from" => _fr} = plan}) do
    case validate_params(Map.put(plan, "system_date_time", conn.assigns.date_time)) do
      {:ok, date} ->
        conn
        |> assign(:expanded, conn.query_params["expanded"])
        |> render_plan(%{plan | "date_time" => date})

      {:error, error} ->
        conn
        |> assign(:plan_error, [error])
        |> render(:index)
    end
  end

  def index(conn, _params) do
    render(conn, :index)
  end

  @spec render_plan(Plug.Conn.t, map) :: Plug.Conn.t
  defp render_plan(conn, plan) do
    query = Query.from_query(plan)
    itineraries = Query.get_itineraries(query)
    route_map = routes_for_query(itineraries)
    route_mapper = &Map.get(route_map, &1)
    itinerary_row_lists = itinerary_row_lists(itineraries, route_mapper, plan)

    conn
    |> add_initial_map_markers(query)
    |> render(
      query: query,
      plan_error: MapSet.to_list(query.errors),
      routes: Enum.map(itineraries, &routes_for_itinerary(&1, route_mapper)),
      itinerary_maps:
        Enum.map(itineraries, &TripPlanMap.itinerary_map(&1, route_mapper: route_mapper)),
      related_links:
        Enum.map(itineraries, &RelatedLink.links_for_itinerary(&1, route_by_id: route_mapper)),
      itinerary_row_lists: itinerary_row_lists
    )
  end

  @spec validate_params(map) :: {:ok, NaiveDateTime.t} | {:error, :invalid_date | :too_future}
  def validate_params(%{"date_time" => _dt} = plan) do
    validate_date(plan)
  end

  @spec validate_date(map | {:ok, %{atom => NaiveDateTime.t(), atom => DateTime.t()}}) ::
          {:ok, DateTime.t()} | {:error, %{atom => String.t()}}
  defp validate_date(%{"date_time" => %{
         "year" => year,
         "month" => month,
         "day" => day,
         "hour" => hour,
         "minute" => minute,
         "am_pm" => am_pm
       }} = plan) do
    case convert_to_date("#{year}-#{month}-#{day} #{hour}:#{minute} #{am_pm}") do
      %NaiveDateTime{} = naive_date ->
        validate_date({:ok, %{plan | "date_time" => naive_date}})
      _ ->
        {:error, :invalid_date}
    end
  end

  defp validate_date({:ok, %{"date_time" => naive_date, "system_date_time" => date_time}}) do
    timezoned_date = future_date_or_now(naive_date, date_time)
    service_date = Util.service_date(timezoned_date)
    end_date = Schedules.Repo.end_of_rating()

    if Date.compare(service_date, end_date) == :gt do
      {:error, :too_future}
    else
      {:ok, timezoned_date}
    end
  end

  defp validate_date(_) do
    {:error, :invalid_date}
  end

  @spec convert_to_date(String.t()) :: NaiveDateTime.t() | nil
  defp convert_to_date(date_string) do
    {result, date_time} = Timex.parse(date_string, "{YYYY}-{M}-{D} {_h24}:{_m} {AM}")

    case {result, Timex.is_valid?(date_time)} do
      {:ok, true} -> date_time
      {_, _} -> nil
    end
  end

  @doc """
  Converts a NaiveDateTime to another zone, and takes the later of the two times.

  ## Examples

      iex> import SiteWeb.TripPlanController
      iex> in_edt = Timex.to_datetime(~N[2017-11-02T13:00:00], "America/New_York")
      iex> future_date_or_now(~N[2017-11-02T12:00:00], in_edt)
      #DateTime<2017-11-02 13:00:00-04:00 EDT America/New_York>
      iex> future_date_or_now(~N[2017-11-05T01:30:00], in_edt)
      #DateTime<2017-11-05 01:30:00-04:00 EDT America/New_York>
      iex> future_date_or_now(~N[2017-11-05T02:00:00], in_edt)
      #DateTime<2017-11-05 02:00:00-05:00 EST America/New_York>
      iex> future_date_or_now(~N[2017-12-01T12:00:00], in_edt)
      #DateTime<2017-12-01 12:00:00-05:00 EST America/New_York>
  """
  @spec future_date_or_now(NaiveDateTime.t(), DateTime.t()) :: DateTime.t()
  def future_date_or_now(naive_date, system_date_time) do
    local_date_time =
      case Timex.to_datetime(naive_date, system_date_time.time_zone) do
        %DateTime{} = dt ->
          dt

        %Timex.AmbiguousDateTime{before: before} ->
          # if you select a date/time during the DST transition, the service
          # will still be running under the previous timezone. Therefore, we
          # pick the "before" time which is n the original zone.
          before
      end

    if Timex.after?(local_date_time, system_date_time) do
      local_date_time
    else
      system_date_time
    end
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  @spec itinerary_row_lists([Itinerary.t()], route_mapper, map) :: [ItineraryRowList.t()]
  defp itinerary_row_lists(itineraries, route_mapper, plan) do
    deps = %ItineraryRow.Dependencies{route_mapper: route_mapper}
    Enum.map(itineraries, &ItineraryRowList.from_itinerary(&1, deps, to_and_from(plan)))
  end

  def assign_initial_map(conn, _opts) do
    conn
    |> assign(:initial_map_src, TripPlanMap.initial_map_src())
    |> assign(:initial_map_data, TripPlanMap.initial_map_data())
  end

  @doc """
  Adds markers to the initial map in the case where there was an error retrieving
  results, but at least one of the inputs resolved to an address with a lat/lng.
  """
  @spec add_initial_map_markers(Plug.Conn.t(), Query.t()) :: Plug.Conn.t()
  def add_initial_map_markers(%Plug.Conn{assigns: %{initial_map_data: map}} = conn, query) do
    map_with_markers =
      map
      |> add_initial_map_marker(query, :to)
      |> add_initial_map_marker(query, :from)

    assign(conn, :initial_map_data, map_with_markers)
  end

  @spec add_initial_map_marker(MapData.t(), Query.t(), :to | :from) :: MapData.t()
  defp add_initial_map_marker(%MapData{} = map, %Query{} = query, field)
       when field in [:to, :from] do
    query
    |> Map.get(field)
    |> do_add_initial_map_marker(map, field)
  end

  @spec do_add_initial_map_marker(
          NamedPosition.t() | {:error, atom},
          MapData.t(),
          :to | :from
        ) :: MapData.t()
  defp do_add_initial_map_marker({:error, _}, %MapData{} = map, _) do
    map
  end
  defp do_add_initial_map_marker(%NamedPosition{} = pos, %MapData{} = map, field) do
    index_map = marker_index_map(field)

    icon_name = Site.TripPlan.Map.stop_icon_name(index_map)
    label = Site.TripPlan.Map.stop_icon_label(index_map)

    marker = Marker.new(pos.latitude, pos.longitude, [
      id: "marker-" <> label.text,
      icon: icon_name,
      size: Site.TripPlan.Map.stop_icon_size(icon_name),
      label: label,
      tooltip: pos.name,
      z_index: 0,
    ])

    MapData.add_marker(map, marker)
  end

  @spec marker_index_map(:from | :to) :: Site.TripPlan.Map.index_map()
  defp marker_index_map(:from), do: %{start: 0, current: 0}
  defp marker_index_map(:to), do: %{current: 1, end: 1}

  @spec modes(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def modes(%Plug.Conn{params: %{"plan" => %{"modes" => modes}}} = conn, _) do
    assign(
      conn,
      :modes,
      Map.new(modes, fn {mode, active?} -> {String.to_existing_atom(mode), active? === "true"} end)
    )
  end

  def modes(%Plug.Conn{} = conn, _) do
    assign(conn, :modes, %{})
  end

  @spec breadcrumbs(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  defp breadcrumbs(conn, _) do
    assign(conn, :breadcrumbs, [Breadcrumb.build("Trip Planner")])
  end

  @spec optimize_for(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def optimize_for(%Plug.Conn{params: %{"plan" => %{"optimize_for" => val}}} = conn, _) do
    assign(conn, :optimize_for, val)
  end

  def optimize_for(%Plug.Conn{} = conn, _) do
    assign(conn, :optimize_for, "best_route")
  end

  @spec routes_for_query([Itinerary.t()]) :: route_map
  defp routes_for_query(itineraries) do
    itineraries
    |> Enum.flat_map(&Itinerary.route_ids/1)
    |> add_additional_routes()
    |> Enum.uniq()
    |> Map.new(&{&1, Routes.Repo.get(&1)})
  end

  @spec routes_for_itinerary(Itinerary.t(), route_mapper) :: [Routes.Route.t()]
  defp routes_for_itinerary(itinerary, route_mapper) do
    itinerary
    |> Itinerary.route_ids()
    |> Enum.map(route_mapper)
  end

  @spec to_and_from(map) :: [to: String.t() | nil, from: String.t() | nil]
  def to_and_from(plan) do
    [to: Map.get(plan, "to"), from: Map.get(plan, "from")]
  end

  defp add_additional_routes(ids) do
    if Enum.any?(ids, &String.starts_with?(&1, "Green")) do
      Enum.concat(ids, GreenLine.branch_ids()) # no cover
    else
      ids
    end
  end
end
