defmodule Site.StationController do
  use Site.Web, :controller

  alias Stations.Station
  alias Stations.Repo

  def index(conn, _params) do
    stations = Repo.all
    render(conn, "index.html", stations: stations)
  end

  def show(conn, %{"id" => id}) do
    station = Repo.get!(Station, id |> String.replace("+", " "))
    conn
    |> assign_parking(station.parkings)
    |> render("show.html", station: station)
  end

  def assign_parking(conn, parkings) do
    conn
    |> assign(:parking_rate, parking_rate(parkings))
    |> assign(:parking_manager, parking_manger(parkings))
    |> assign(:parking_space_counts, parking_space_counts(parkings))
    |> assign(:parking_note, parking_note(parkings))
  end

  def parking_rate(parkings) do
    parkings
    |> first_not_empty(:rate)
  end

  def parking_manger(parkings) do
    parkings
    |> first_not_empty(:manager)
  end

  def parking_space_counts(parkings) do
    parkings
    |> Enum.filter(&(&1.spots > 0))
    |> Enum.map(&({friendly_type(&1.type), &1.spots}))
  end

  def parking_note(parkings) do
    parkings
    |> first_not_empty(:note)
  end

  defp first_not_empty(enum, key) do
    case Enum.find(enum, &(!empty?(Map.from_struct(&1)[key]))) do
      nil -> nil
      found -> Map.from_struct(found)[key]
    end
  end

  defp empty?(nil), do: true
  defp empty?(""), do: true
  defp empty?(_), do: false

  defp friendly_type("basic"), do: "Parking"
  defp friendly_type(type), do: type |> String.capitalize
end
