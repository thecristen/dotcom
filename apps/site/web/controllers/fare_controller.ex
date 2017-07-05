defmodule Site.FareController do
  use Site.Web, :controller

  alias Site.FareController.{Commuter, BusSubway, Ferry, Filter}
  alias Fares.{Format, Repo}

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
    |> assign(:breadcrumbs, ["Fares and Passes"])
    |> await_assign_all()
    |> render("index.html")
  end

  def show(conn, %{"id" => static}) when static in @static_pages do
    render conn, "#{static}.html", [
      breadcrumbs: [
        {fare_path(conn, :index), "Fares and Passes"},
        @static_page_titles[static]
      ]
    ]
  end
  def show(conn, %{"id" => "retail_sales_locations"} = params) do
    conn
    |> assign_fare_sales_locations(params)
    |> render("retail_sales_locations.html")
  end
  def show(conn, params) do
    params["id"]
    |> fare_module
    |> render_fare_module(conn)
  end

  defp assign_fare_sales_locations(conn, %{"lat" => lat, "long" => long}) do
    position = %{latitude: String.to_float(lat), longitude: String.to_float(long)}
    conn
    |> assign(:search_position, position)
    |> assign(:fare_sales_locations, Fares.RetailLocations.get_nearby(position))
  end
  defp assign_fare_sales_locations(conn, _params) do
    conn
    |> assign(:fare_sales_locations, [])
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
