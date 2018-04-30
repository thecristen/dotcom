defmodule SiteWeb.FareController do
  use SiteWeb, :controller

  alias SiteWeb.FareController.{Commuter, BusSubway, Ferry, Filter}
  alias Fares.{Format, Repo, RetailLocations}

  @options %{
    geocode_fn: &GoogleMaps.Geocode.geocode/1,
    nearby_fn: &Fares.RetailLocations.get_nearby/1
  }

  @bus_subway_filters [[name: :subway, duration: :single_trip, reduced: nil],
                       [name: :local_bus, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]
  @commuter_and_ferry_filters [[mode: :commuter_rail, duration: :single_trip, reduced: nil],
                               [mode: :ferry, duration: :single_trip, reduced: nil]]
  @the_ride_filters [[mode: :the_ride]]

  @simple_subway_filter [mode: :subway, duration: :single_trip, media: [:charlie_card]]
  @simple_bus_filter [mode: :bus, name: :local_bus, duration: :single_trip, media: [:charlie_card]]

  def index(conn, _params) do
    conn
    |> async_assign(:simple_subway_price, fn -> simple_price(@simple_subway_filter) end)
    |> async_assign(:simple_bus_price, fn -> simple_price(@simple_bus_filter) end)
    |> async_assign(:bus_subway, fn -> format_filters(@bus_subway_filters, :bus_subway) end)
    |> async_assign(:the_ride, fn -> format_filters(@the_ride_filters, :the_ride) end)
    |> async_assign(:commuter_and_ferry, fn ->
       format_filters(@commuter_and_ferry_filters, [:commuter_rail, :ferry]) end)
    |> assign(:breadcrumbs, [Breadcrumb.build("Fares")])
    |> await_assign_all()
    |> render("index.html")
  end

  def show(%Plug.Conn{assigns: %{date_time: date_time}} = conn, %{"id" => "retail-sales-locations"} = params) do
    {position, formatted} = calculate_position(params, @options.geocode_fn)

    conn
    |> assign(:breadcrumbs, [
        Breadcrumb.build("Fares", fare_path(conn, :index)),
        Breadcrumb.build("Retail Sales Locations")
      ])
    |> render("retail_sales_locations.html",
         current_pass: current_pass(date_time),
         requires_google_maps?: true,
         fare_sales_locations: fare_sales_locations(position, @options.nearby_fn),
         address: formatted,
         search_position: position
       )
  end
  def show(conn, %{"id" => "commuter-rail"}) do
    render_fare_module(Commuter, conn)
  end
  def show(conn, %{"id" => "ferry"}) do
    render_fare_module(Ferry, conn)
  end
  def show(conn, %{"id" => "bus-subway"}) do
    render_fare_module(BusSubway, conn)
  end
  def show(conn, _) do
    check_cms_or_404(conn)
  end

  @spec calculate_position(map(),
    (String.t -> GoogleMaps.Geocode.Address.t)) :: {GoogleMaps.Geocode.Address.t, String.t}
  def calculate_position(%{"location" => %{"address" => address}}, geocode_fn) do
    address
    |> geocode_fn.()
    |> parse_geocode_response
  end
  def calculate_position(_params, _geocode_fn) do
    {%{}, ""}
  end

  @spec current_pass(DateTime.t) :: String.t
  def current_pass(%{day: day} = date) when day < 15 do
    Timex.format!(date, "{Mfull} {YYYY}")
  end
  def current_pass(date) do
    next_month = Timex.shift(date, months: 1)
    Timex.format!(next_month, "{Mfull} {YYYY}")
  end

  defp parse_geocode_response({:ok, [location | _]}) do
    {location, location.formatted}
  end
  defp parse_geocode_response(_) do
    {%{}, ""}
  end

  @spec fare_sales_locations(GoogleMaps.Geocode.Address.t,
    (GoogleMaps.Geocode.Address.t -> [{RetailLocations.Location.t, float}])) :: [{RetailLocations.Location.t, float}]
  def fare_sales_locations(%{latitude: _lat, longitude: _long} = position, nearby_fn) do
    nearby_fn.(position)
  end
  def fare_sales_locations(%{}, _nearby_fn) do
    []
  end

  defp format_filters(filters, :the_ride) do
    Enum.flat_map(filters, &Repo.all/1)
  end
  defp format_filters(filters, type) do
    filters
    |> Enum.flat_map(&Repo.all/1)
    |> Format.summarize(type)
  end

  @spec simple_price(Keyword.t) :: String.t
  defp simple_price(criteria) do
    criteria
    |> Fares.Repo.all()
    |> single_fare()
    |> Format.price()
  end

  # Intentionally fail if there is more than one result.
  @spec single_fare([Fares.Fare.t]) :: Fares.Fare.t
  defp single_fare([fare]), do: fare

  @spec render_fare_module(module, Plug.Conn.t) :: Plug.Conn.t
  defp render_fare_module(module, conn) do
    conn = conn
    |> assign(:fare_type, fare_type(conn))
    |> module.before_render

    fares = conn
    |> module.fares
    |> filter_reduced(conn.assigns.fare_type)

    filters = module.filters(fares)
    selected_filter = selected_filter(filters, conn.params["filter"])

    conn
    |> render(
      "show.html",
      fare_template: apply(module, :template, []),
      selected_filter: selected_filter,
      filters: filters)
  end

  def zone(conn, _params) do
    fare_zone_info = gather_fare_zone_info()

    conn
    |> assign(:fare_zone_info, fare_zone_info)
    |> assign(:breadcrumbs, [Breadcrumb.build("Commuter Rail Fare Zones")])
    |> render("_zone.html")
  end

  defp gather_fare_zone_info do
    Fares.Repo.grouped_commuter_fares
    |> Enum.sort(&Fares.CommuterFareGroup.sort_fares/2)
  end

  defp fare_type(%{params: %{"fare_type" => fare_type}}) when fare_type in ["senior_disabled", "student"] do
    String.to_existing_atom(fare_type)
  end
  defp fare_type(_) do
    nil
  end

  def filter_reduced(fares, reduced) when is_atom(reduced) or is_nil(reduced) do
    fares
    |> Enum.filter(&match?(%{reduced: ^reduced}, &1))
  end

  def selected_filter(filters, filter_id)
  def selected_filter([], _) do
    nil
  end
  def selected_filter([filter | _], nil) do
    filter
  end
  def selected_filter(filters, filter_id) do
    case Enum.find(filters, &match?(%Filter{id: ^filter_id}, &1)) do
      nil -> selected_filter(filters, nil)
      found -> found
    end
  end
end
