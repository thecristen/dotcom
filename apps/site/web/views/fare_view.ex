defmodule Site.FareView do
  use Site.Web, :view

  alias Fares.Fare

  def zone_name({zone, number}) do
    "#{String.capitalize(Atom.to_string(zone))} #{number}"
  end

  def fare_price(fare_in_cents) do
    "$#{Float.to_string(fare_in_cents / 100, decimals: 2)}"
  end

  def fare_duration(%Fare{duration: :month, pass_type: :mticket}) do
    "Monthly Pass on mTicket app"
  end
  def fare_duration(%Fare{duration: :month}) do
    "Monthly Pass"
  end
  def fare_duration(%Fare{duration: :round_trip}) do
    "Round Trip"
  end
  def fare_duration(%Fare{duration: :single_trip}) do
    "One Way"
  end

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
    "Valid for the #{fare_name(fare)} only."
  end
  def description(%Fare{mode: :ferry, duration: :month, pass_type: :mticket} = fare) do
    "Valid for one calendar month of unlimited travel on the #{fare_name(fare)} only."
  end
  def description(%Fare{mode: :ferry, duration: :month} = fare) do
    "Valid for one calendar month of unlimited travel on the #{fare_name(fare)} as well as the Local Bus, \
Subway, Express Buses, and Commuter Rail up to Zone 5."
  end

  def eligibility(%Fare{mode: mode, reduced: :student}) do
    "Middle and high school students are eligible for reduced fares on the #{route_type_name(mode)}. \
In order to receive a reduced fare, students must use a Student CharlieCard issued by their school. \
One Way fares and Stored Value are eligible for the reduced rate, however 1-Day, 7-Day, and Monthly Passes are \
not. College students may be eligible for reduced fares through a Semester Pass Program. For more information, \
please contact an administrator at your school."
  end
  def eligibility(%Fare{reduced: nil}) do
    "Those who are 12 years of age or older qualify for Adult fare pricing."
  end
  def eligibility(_) do
    nil
  end

  def filter_fares(fares, "adult") do
    fares
    |> Enum.filter(&(&1.reduced == nil))
  end
  def filter_fares(fares, "student") do
    fares
    |> Enum.filter(&(&1.reduced == :student))
  end

  def fare_customers(nil) do
    "Adult"
  end
  def fare_customers(reduced) do
    reduced
    |> Atom.to_string
    |> String.capitalize
  end

  def applicable_fares(nil, 2) do
    [
      %{reduced: nil, duration: :single_trip},
      %{reduced: nil, duration: :round_trip},
      %{reduced: nil, duration: :month},
      %{duration: :month, pass_type: :mticket, reduced: nil}
    ]
  end
  def applicable_fares(reduced, 2) do
    [
      %{reduced: reduced, duration: :single_trip},
      %{reduced: reduced, duration: :round_trip}
    ]
  end
  def applicable_fares(nil, 4) do
    [
      %{reduced: nil, duration: :single_trip},
      %{reduced: nil, duration: :round_trip},
      %{reduced: nil, duration: :month, pass_type: :ticket},
      %{reduced: nil, duration: :month, pass_type: :mticket}
    ]
  end
  def applicable_fares(reduced, 4) do
    [
      %{reduced: reduced, duration: :single_trip},
      %{reduced: reduced, duration: :round_trip}
    ]
  end

  def fare_name(%Fare{mode: :commuter, name: name}), do: zone_name(name)
  def fare_name(%Fare{name: :ferry_inner_harbor}), do: "Inner Harbor Ferry"
  def fare_name(%Fare{name: :ferry_cross_harbor}), do: "Cross Harbor Ferry"
  def fare_name(%Fare{name: :commuter_ferry}), do: "Commuter Ferry"
  def fare_name(%Fare{name: :commuter_ferry_logan}), do: "Commuter Ferry to Logan Airport"

  def vending_machine_stations do
    Stations.Repo.all
    |> Enum.filter(fn station -> station.has_fare_machine end)
  end
end
