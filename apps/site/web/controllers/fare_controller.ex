defmodule Site.FareController do
  use Site.Web, :controller

  alias Site.FareController.{Commuter, BusSubway, Ferry, Summary, Filter}

  @static_page_titles %{
    "reduced" => "Reduced Fare Eligibility",
    "charlie_card" => "The CharlieCard"
  }
  @static_pages Map.keys(@static_page_titles)
  @bus_subway_filters [[name: :subway, duration: :single_trip, reduced: nil],
                       [name: :local_bus, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]
  @commuter_filters [[mode: :commuter, duration: :single_trip, reduced: nil],
                     [mode: :commuter, duration: :month, reduced: nil]]
  @ferry_filters [[mode: :ferry, duration: :single_trip, reduced: nil],
                  [mode: :ferry, duration: :month, reduced: nil]]
  @the_ride_filters [[mode: :the_ride]]

  def index(conn, _params) do
    render conn, "index.html", [
      breadcrumbs: ["Fares and Passes"],
      bus_subway: @bus_subway_filters |> Enum.flat_map(&Fares.Repo.all/1) |> summarize_bus,
      commuter: @commuter_filters |> Enum.flat_map(&Fares.Repo.all/1) |> summarize_commuter,
      ferry: @ferry_filters |> Enum.flat_map(&Fares.Repo.all/1) |> summarize_ferry,
      the_ride: @the_ride_filters |> Enum.flat_map(&Fares.Repo.all/1)
    ]
  end

  def show(conn, %{"id" => static}) when static in @static_pages do
    render conn, "#{static}.html", [
      breadcrumbs: [
        {fare_path(conn, :index), "Fares and Passes"},
        @static_page_titles[static]
      ]
    ]
  end

  def show(conn, params) do
    params["id"]
    |> fare_module
    |> render_fare_module(conn)
  end

  defp summarize_bus(fares) do
    for [base|_] = chunk <- Enum.chunk_by(fares, &{&1.name, &1.duration, &1.additional_valid_modes}) do
      %Summary{
        name: Fares.Format.full_name(base),
        modes: [base.mode | base.additional_valid_modes],
        fares: Enum.map(chunk, &{Fares.Format.media(&1), Fares.Format.price(&1)})
      }
    end
  end

  defp summarize_commuter(fares) do
    for [base|_] = chunk <- Enum.chunk_by(fares, &match?(%{duration: :single_trip}, &1)) do
      min_price = Enum.min_by(chunk, &(&1.cents))
      max_price = Enum.max_by(chunk, &(&1.cents))
      %Summary{
        name: Fares.Format.duration(base),
        modes: [base.mode | base.additional_valid_modes],
        fares: [{"Zones 1A-10", [Fares.Format.price(min_price), " - ",
                                 Fares.Format.price(max_price)]}]
      }
    end
  end

  defp summarize_ferry(fares) do
    for [base|_] = chunk <- Enum.chunk_by(fares, &match?(%{duration: :single_trip}, &1)) do
      min_price = Enum.min_by(chunk, &(&1.cents))
      max_price = Enum.max_by(chunk, &(&1.cents))
      %Summary{
        name: Fares.Format.duration(base),
        modes: [base.mode | base.additional_valid_modes],
        fares: [{"All Ferry routes", [Fares.Format.price(min_price), " - ",
                                      Fares.Format.price(max_price)]}]
      }
    end
  end

  defp fare_module("commuter"), do: Commuter
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
      fare_template: module.template,
      selected_filter: selected_filter,
      filters: filters)
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
