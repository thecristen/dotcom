defmodule Site.FareView.Description do
  alias Fares.Fare

  @spec description(Fare.t) :: String.t | iolist
  def description(%Fare{mode: :commuter, duration: :single_trip}) do
    "Valid for Commuter Rail only."
  end
  def description(%Fare{mode: :commuter, duration: :round_trip}) do
    "Valid for Commuter Rail only."
  end
  def description(%Fare{mode: :commuter, duration: :month, pass_type: :mticket, name: name}) do
    ["Valid for one calendar month of travel on the commuter rail ",
     valid_commuter_zones(name),
     " only."
    ]
  end
  def description(%Fare{mode: :commuter, duration: :month, name: name}) do
    ["Valid for one calendar month of unlimited travel on Commuter Rail ",
     valid_commuter_zones(name),
     " as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."]
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
  def description(%Fare{mode: :subway, pass_type: pass_type, duration: :single_trip} = fare)
  when pass_type != :cash_or_ticket do

    [
      "Valid for all Subway lines (includes routes SL1 and SL2). ",
      transfers(fare),
      " Must be done within 2 hours of your original ride."
    ]
  end
  def description(%Fare{mode: :subway, pass_type: :cash_or_ticket}) do
    "Free transfer to Subway, route SL4, and route SL5 when done within 2 hours of purchasing a ticket."
  end
  def description(%Fare{mode: :bus, pass_type: :cash_or_ticket}) do
    "Free transfer to one additional Local Bus included."
  end
  def description(%Fare{mode: :subway, duration: :month, reduced: :student}) do
    ["Unlimited travel for one calendar month on the Subway",
     "Local Bus",
     "Inner Express Bus",
     "Outer Express Bus."
    ] |> AndJoin.join
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
  def description(%Fare{mode: :bus, pass_type: pass_type} = fare)
  when pass_type != :cash_or_ticket do
    [
      "Valid for the Local Bus (includes route SL4 and SL5). ",
      transfers(fare),
      " Must be done within 2 hours of your original ride."
    ]
  end

  defp valid_commuter_zones({:zone, "1A"}) do
    "in Zone 1A only"
  end
  defp valid_commuter_zones({:zone, final}) do
    ["from Zones 1A-", final]
  end
  defp valid_commuter_zones({:interzone, total}) do
    ["between ", total, " zones outside of Zone 1A"]
  end

  def transfers(fare) do
    # used to generate the list of transfer fees for a a given fare.
    # Transfers <= 0 are considered free.
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
    other_fare = transfers_other_fare(name, fare)
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
     "."
    ]
  end

  defp transfers_map({name, text}, fare) do
    other_fare = transfers_other_fare(name, fare)
    [" Transfer to ", text, " ", Fares.Format.price(other_fare.cents - fare.cents), "."]
  end

  defp transfers_other_fare(name, fare) do
    case {fare, name, Fares.Repo.all(name: name, pass_type: fare.pass_type, duration: fare.duration)} do
      {_, _, [other_fare]} -> other_fare
    end
  end
end
