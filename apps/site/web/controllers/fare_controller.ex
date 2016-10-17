defmodule Site.FareController do
  use Site.Web, :controller

  def index(conn, _params) do

    conn
    |> assign_params
    |> assign_origin_stops
    |> assign_destination_stops
    |> assign_key_stops
    |> assign_fares
    |> render("index.html")
  end

  defp assign_origin_stops(conn) do
    origin_stops = Stations.Repo.all
    |> Enum.filter(&commuter_rail_station?/1)

    assign(conn, :origin_stops, origin_stops)
  end

  def commuter_rail_station?(station) do
    station.id
    |> Routes.Repo.by_stop
    |> Enum.filter(&(&1.type == 2))
    |> Enum.empty?
    |> Kernel.!
  end

  defp assign_params(conn) do
    Enum.reduce [:origin, :destination], conn, fn (param, conn) ->
      case Map.get(conn.params, Atom.to_string(param)) do
        "" -> assign conn, param, nil
        value -> assign conn, param, value
      end
    end
  end

  defp assign_destination_stops(%{assigns: %{origin: nil}} = conn) do
    assign(conn, :destination_stops, [])
  end
  defp assign_destination_stops(%{assigns: %{origin: origin}} = conn) do
    origin
    |> Routes.Repo.by_stop
    |> Enum.filter_map(&(&1.type == 2), &(Schedules.Repo.stops &1.id, []))
    |> Enum.concat
    |> Enum.uniq
    |> Enum.sort_by(&(&1.name))
    |> (fn stop -> assign(conn, :destination_stops, stop) end).()
  end

  def assign_key_stops(conn) do
    conn
    |> assign(:key_stops, Enum.map(["place-sstat", "place-north", "place-bbsta"], &Stations.Repo.get/1))
  end

  defp assign_fares(conn) do
    if(conn.params["origin"] && conn.params["destination"]) do
      fare_name = Fares.calculate(Zones.Repo.get(conn.params["origin"]), Zones.Repo.get(conn.params["destination"]))

      %{
        nil => adult_fares,
        :student => student_fares,
        :senior_disabled => senior_fares
      } = [name: fare_name]
      |> Fares.Repo.all()
      |> Enum.group_by(&(&1.reduced))
    end

    conn
    |> assign(:adult_fares, adult_fares || [])
    |> assign(:student_fares, student_fares || [])
    |> assign(:senior_fares, senior_fares || [])
  end
end
