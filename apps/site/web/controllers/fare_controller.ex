defmodule Site.FareController do
  use Site.Web, :controller

  alias Site.FareController.{Commuter, BusSubway, Ferry, Filter}

  @static_pages ["reduced", "charlie_card"]

  def show(conn, %{"id" => static}) when static in @static_pages do
    render conn, "#{static}.html", []
  end

  def show(conn, params) do
    params["id"]
    |> fare_module
    |> render_fare_module(conn)
  end

  defp fare_module("commuter"), do: Commuter
  defp fare_module("ferry"), do: Ferry
  defp fare_module("bus_subway"), do: BusSubway
  defp fare_module(_), do: nil

  defp render_fare_module(nil, conn) do
    # TODO redirect to `fare_path(conn, :index)` when it exists
    conn
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
