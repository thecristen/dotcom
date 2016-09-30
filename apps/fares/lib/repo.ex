defmodule Fares.Repo.ZoneFares do
  def fare_info do
    filename = "priv/zone_fares.csv"

    filename
    |> File.stream!
    |> CSV.decode
    |> Enum.flat_map(&mapper/1)
  end

  def mapper([zone, single_trip, single_trip_reduced, monthly]) do
    [
      %Fare{name: String.to_atom(zone), duration: :single_trip, pass_type: :ticket, reduced: nil, cents: round(String.to_float(single_trip) * 100)},
      %Fare{name: String.to_atom(zone), duration: :single_trip, pass_type: :ticket, reduced: :student, cents: round(String.to_float(single_trip_reduced) * 100)},
      %Fare{name: String.to_atom(zone), duration: :single_trip, pass_type: :ticket, reduced: :senior_disabled, cents: round(String.to_float(single_trip_reduced) * 100)},
      %Fare{name: String.to_atom(zone), duration: :month, pass_type: :ticket, reduced: nil, cents: round(String.to_float(monthly) * 100)}
    ]
  end
end

defmodule Fares.Repo do
  import Fares.Repo.ZoneFares
  @zone_fares fare_info

  def all(opts \\ []) do
    @zone_fares
    |> filter(opts)
  end

  def filter(fares, opts) do
    fares
    |> filter_all(Enum.into(opts, %{}))
  end

  defp filter_all(fares, opts) do
    Enum.filter(fares, fn fare -> match?(^opts, Map.take(fare, Map.keys(opts))) end)
  end
end
