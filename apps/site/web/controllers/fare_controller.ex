defmodule Site.FareController do
  use Site.Web, :controller

  alias Site.FareController.{Commuter, BusSubway, Ferry, Filter}
  alias Fares.{Format, Repo, RetailLocations}

  @options %{
    geocode_fn: &GoogleMaps.Geocode.geocode/1,
    nearby_fn: &Fares.RetailLocations.get_nearby/1
  }

  @static_page_titles %{
    "reduced" => "Reduced Fare Eligibility",
    "charlie_card" => "The CharlieCard",
    "payment_methods" => "Payment Methods"
  }
  @static_pages Map.keys(@static_page_titles)
  @bus_subway_filters [[name: :subway, duration: :single_trip, reduced: nil],
                       [name: :local_bus, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]
  @commuter_rail_filters [[mode: :commuter_rail, duration: :single_trip, reduced: nil],
                     [mode: :commuter_rail, duration: :month, reduced: nil]]
  @ferry_filters [[mode: :ferry, duration: :single_trip, reduced: nil],
                  [mode: :ferry, duration: :month, reduced: nil]]
  @the_ride_filters [[mode: :the_ride]]

  def index(conn, _params) do
    conn
    |> async_assign(:bus_subway, fn -> format_filters(@bus_subway_filters, :bus_subway) end)
    |> async_assign(:commuter_rail, fn -> format_filters(@commuter_rail_filters, :commuter_rail) end)
    |> async_assign(:ferry, fn -> format_filters(@ferry_filters, :ferry) end)
    |> async_assign(:the_ride, fn -> format_filters(@the_ride_filters, :the_ride) end)
    |> assign(:breadcrumbs, [Breadcrumb.build("Fares and Passes")])
    |> await_assign_all()
    |> render("index.html")
  end

  def show(conn, %{"id" => static}) when static in @static_pages do
    render conn, "#{static}.html", [
      breadcrumbs: [
        Breadcrumb.build("Fares and Passes", fare_path(conn, :index)),
        Breadcrumb.build(@static_page_titles[static])
      ]
    ]
  end
  def show(%Plug.Conn{assigns: %{date_time: date_time}} = conn, %{"id" => "retail_sales_locations"} = params) do
    {position, formatted} = calculate_position(params, @options.geocode_fn)

    conn
    |> assign(:breadcrumbs, [
        Breadcrumb.build("Fares and Passes", fare_path(conn, :index)),
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
  def show(conn, params) do
    params["id"]
    |> fare_module
    |> render_fare_module(conn)
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

  defp fare_module("commuter_rail"), do: Commuter
  defp fare_module("ferry"), do: Ferry
  defp fare_module("bus_subway"), do: BusSubway
  defp fare_module(_), do: nil

  defp render_fare_module(nil, conn) do
    conn
    |> redirect(to: fare_path(conn, :index))
    |> halt
  end
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
