defmodule Site.FareView.Description do
  alias Fares.Fare

  def description(%Fare{mode: :commuter, duration: :single_trip}) do
    "Valid for Commuter Rail only."
  end
  def description(%Fare{mode: :commuter, duration: :round_trip}) do
    "Valid for Commuter Rail only."
  end
  def description(%Fare{mode: :commuter, duration: :month, pass_type: :mticket, name: {_, "1A"}}) do
    "Valid for one calendar month of travel on the commuter rail in zone 1A only."
  end
  def description(%Fare{mode: :commuter, duration: :month, pass_type: :mticket, name: {_zone, number}}) do
    "Valid for one calendar month of travel on the commuter rail from zones 1A-#{number} only."
  end
  def description(%Fare{mode: :commuter, duration: :month, name: {_, "1A"}}) do
    "Valid for one calendar month of unlimited travel on Commuter Rail in zone 1A as well as Local Bus, Subway, \
Express Bus, and the Charlestown Ferry."
  end
  def description(%Fare{mode: :commuter, duration: :month, name: {_zone, number}}) do
    "Valid for one calendar month of unlimited travel on Commuter Rail from Zones 1A-#{number} as well as Local \
Bus, Subway, Express Bus, and the Charlestown Ferry."
  end
  def description(%Fare{mode: :ferry, duration: duration} = fare) when duration in [:round_trip, :single_trip] do
    [
      "Valid for the ",
      Fares.Format.name(fare),
      " only."
    ]
  end
  def description(%Fare{mode: :ferry, duration: :month, pass_type: :mticket} = fare) do
       [
         "Valid for one calendar month of unlimited travel on the ",
         Fares.Format.name(fare),
         " only."
       ]
  end
  def description(%Fare{mode: :ferry, duration: :month} = fare) do
    [
      "Valid for one calendar month of unlimited travel on the ",
      Fares.Format.name(fare),
      " as well as the Local Bus, \
 Subway, Express Buses, and Commuter Rail up to Zone 5."
    ]
  end
  def description(%Fare{name: name, duration: :single_trip, pass_type: :cash_or_ticket})
  when name in [:inner_express_bus, :outer_express_bus] do
    "No free or discounted transfers."
  end
  def description(%Fare{mode: :subway, pass_type: :charlie_card, duration: :single_trip} = fare) do

    [
      "Valid for all Subway lines (includes routes SL1 and SL2). ",
      transfers(fare),
      "Must be done within 2 hours of your original ride."
    ]
  end
  def description(%Fare{mode: :subway, pass_type: :cash_or_ticket}) do
    "Free transfer to Subway, route SL4, and route SL5 when done within 2 hours of purchasing a ticket."
  end
  def description(%Fare{mode: :bus, pass_type: :charlie_card} = fare) do
    [
      "Valid for the Local Bus (includes route SL4 and SL5). ",
      transfers(fare),
      "Must be done within 2 hours of your original ride."
    ]
  end
  def description(%Fare{mode: :bus, pass_type: :cash_or_ticket}) do
    "Free transfer to one additional Local Bus included."
  end
  def description(%Fare{mode: :subway, duration: :month}) do
    "Unlimited travel for one calendar month on the Local Bus and Subway."
  end
  def description(%Fare{mode: :subway, duration: duration}) when duration in [:day, :week] do
    "Can be used for the Subway, Bus, Commuter Rail Zone 1A, and the Charlestown Ferry."
  end
  def description(%Fare{name: :local_bus, duration: :month}) do
    "Unlimited travel for one calendar month on the Local Bus (not including routes SL1 or SL2)."
  end
  def description(%Fare{name: :inner_express_bus, duration: :month}) do
    ["Unlimited travel for one calendar month on the Inner Express Bus",
     "Local Bus",
     "Commuter Rail Zone 1A",
     "the Charlestown Ferry."
    ] |> AndJoin.join
  end
  def description(%Fare{name: :outer_express_bus, duration: :month}) do
    ["Unlimited travel for one calendar month on the Outer Express Bus as well as the Inner Express Bus",
     "Local Bus",
     "Commuter Rail Zone 1A",
     "the Charlestown Ferry."
    ] |> AndJoin.join
  end
  def description(%Fare{}) do
    "missing description"
  end

  def transfers(fare) do
    # used to generate the list of transfer fees for a a given fare.  Filters out transfers which are <= 0.
    {paid, free} = [subway: "Subway",
                    local_bus: "Local Bus",
                    inner_express_bus: "Inner Express Bus",
                    outer_express_bus: "Outer Express Bus"]
                    |> Enum.partition(&transfers_filter(&1, fare))
    [
      free_transfers(free),
      Enum.map(paid, &transfers_map(&1, fare))
    ]
  end

  defp transfers_filter({name, _}, fare) do
    other_fare = transfers_other_fare(name)
    other_fare.cents > fare.cents
  end

  defp free_transfers([]) do
    []
  end
  defp free_transfers(names_and_texts) do
    ["Free transfers to ",
     names_and_texts
     |> Enum.map(&elem(&1, 1))
     |> AndJoin.join,
     ". "
    ]
  end

  defp transfers_map({name, text}, fare) do
    other_fare = transfers_other_fare(name)
    ["Transfer to ", text, " ", Fares.Format.price(other_fare.cents - fare.cents), ". "]
  end

  defp transfers_other_fare(name) do
    [name: name, pass_type: :charlie_card, duration: :single_trip]
    |> Fares.Repo.all
    |> List.first
  end
end
