defmodule Site.FareController.BusSubway do
  use Site.FareController.Behaviour
  alias Site.FareController.Filter

  def mode_name(), do: "Bus/Subway"

  def template(), do: "bus_subway.html"

  def fares(_conn) do
    [:subway, :bus]
    |> Enum.flat_map(&Fares.Repo.all(mode: &1))
  end

  def filters([example_fare | _] = fares) do
    [
      %Filter{
        id: "",
        name: [
          Fares.Format.name(example_fare),
          " ",
          Fares.Format.customers(example_fare),
          " Fares"
        ],
        fares: fares
      }
    ]
  end
end
