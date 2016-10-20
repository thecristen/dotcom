defmodule Site.FareController.Commuter do
  use Site.Fare.FareBehaviour

  alias Schedules.Stop

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def fares(origin, destination) when not is_nil(origin) and not is_nil(destination) do
    fare_name = Fares.calculate(Zones.Repo.get(origin.id), Zones.Repo.get(destination.id))
    [name: fare_name]
    |> Fares.Repo.all()
  end
  def fares(_origin, _destination) do
    []
  end

  def key_stops do
    [
      %Stop{id: "place-sstat", name: "South Station"},
      %Stop{id: "place-north", name: "North Station"},
      %Stop{id: "place-bbsta", name: "Back Bay"}
    ]
  end

  def applicable_fares(nil) do
    [%{reduced: nil, duration: :single_trip},
     %{reduced: nil, duration: :round_trip},
     %{reduced: nil, duration: :month},
     %{duration: :month, pass_type: :mticket, reduced: nil}]
  end
  def applicable_fares(reduced) do
    [%{reduced: reduced, duration: :single_trip},
     %{reduced: reduced, duration: :round_trip}]
  end
end
