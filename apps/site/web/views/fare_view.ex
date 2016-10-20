defmodule Site.FareView do
  use Site.Web, :view

  alias Fares.Fare

  def zone_name({zone, number}) do
    "#{zone} #{number}"
    |> String.capitalize
  end

  def fare_price(fare_in_cents) do
    "$#{Float.to_string(fare_in_cents / 100, decimals: 2)}"
  end

  def fare_duration_summary(:month) do
    "1 Month"
  end
  def fare_duration_summary(:round_trip) do
    "Round Trip"
  end
  def fare_duration_summary(:single_trip) do
    "One Way"
  end
  def fare_duration_summary(:day) do
    "1 Day"
  end
  def fare_duration_summary(:week) do
    "7 Days"
  end

  @spec fare_duration(Fares.Fare.t) :: String.t
  def fare_duration(%Fare{mode: mode, duration: :single_trip}) when mode in [:subway, :bus] do
    "Single Ride"
  end
  def fare_duration(%Fare{duration: :single_trip}) do
    "One Way"
  end
  def fare_duration(%Fare{duration: :round_trip}) do
    "Round Trip"
  end
  def fare_duration(%Fare{duration: :day}) do
    "Day Pass"
  end
  def fare_duration(%Fare{duration: :week}) do
    "7-Day Pass"
  end
  def fare_duration(%Fare{duration: :month, pass_type: :mticket}) do
    "Monthly Pass on mTicket App"
  end
  def fare_duration(%Fare{duration: :month}) do
    "Monthly Pass"
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
  def description(%Fare{mode: :subway, duration: :single_trip}) do
    "Free transfer to Subway and Local Bus. \
    Transfer to Inner Express Bus $1.75. \
    Transfer to Outer Express Bus $3.00. \
    Must be done within 2 hours of your original ride."
  end
  def description(%Fare{}) do
    "missing description"
  end

  def eligibility(%Fare{mode: mode, reduced: :student}) do
    "Middle and high school students are eligible for reduced fares on the #{route_type_name(mode)}. \
In order to receive a reduced fare, students must use a Student CharlieCard issued by their school. \
One Way fares and Stored Value are eligible for the reduced rate, however 1-Day, 7-Day, and Monthly Passes are \
not. College students may be eligible for reduced fares through a Semester Pass Program. For more information, \
please contact an administrator at your school."
  end
  def eligibility(%Fare{mode: mode, reduced: :senior_disabled}) do
    "Those who are 65 years of age or older and persons with disabilities qualify for a reduced fare on the \
#{route_type_name(mode)}. In order to receive a reduced fare, seniors must obtain a Senior CharlieCard and \
persons with disabilities must apply for a Transportation Access Pass (TAP). One Way fares and Stored Value \
are eligible for the reduced rate, however 1-Day, 7-Day, and Monthly Passes are not."
  end
  def eligibility(%Fare{reduced: nil}) do
    "Those who are 12 years of age or older qualify for Adult fare pricing."
  end
  def eligibility(_) do
    nil
  end

  def filter_reduced(fares, :adult) do
    filter_reduced(fares, nil)
  end
  def filter_reduced(fares, reduced) when is_atom(reduced) or is_nil(reduced) do
    fares
    |> Enum.filter(&match?(%{reduced: ^reduced}, &1))
  end

  def fare_customers(type) when type in [nil, :adult], do: "Adult"
  def fare_customers(:student), do: "Student"
  def fare_customers(:senior_disabled), do: "Senior & Disabilities"

  def display_fare_type(fare_type) do
    fare_type
    |> fare_customers
  end

  def fare_name(%Fare{mode: :commuter, name: name}), do: zone_name(name)
  def fare_name(%Fare{name: :ferry_inner_harbor}), do: "Inner Harbor Ferry"
  def fare_name(%Fare{name: :ferry_cross_harbor}), do: "Cross Harbor Ferry"
  def fare_name(%Fare{name: :commuter_ferry}), do: "Commuter Ferry"
  def fare_name(%Fare{name: :commuter_ferry_logan}), do: "Commuter Ferry to Logan Airport"
  def fare_name(%Fare{name: :subway}), do: "Subway"
  def fare_name(%Fare{name: :local_bus}), do: "Local Bus"
  def fare_name(%Fare{name: :inner_express_bus}), do: "Inner Express Bus"
  def fare_name(%Fare{name: :outer_express_bus}), do: "Outer Express Bus"

  def fare_media(%Fare{pass_type: :charlie_card}), do: "CharlieCard"
  def fare_media(%Fare{pass_type: :ticket}), do: "Ticket or Cash"
  def fare_media(%Fare{pass_type: :mticket}), do: "mTicket App"
  def fare_media(%Fare{pass_type: :card_or_ticket}), do: "CharlieCard or Ticket"
  def fare_media(%Fare{pass_type: :senior_card}), do: "Senior CharlieCard or TAP ID"
  def fare_media(%Fare{pass_type: :student_card}), do: "Student CharlieCard"

  def vending_machine_stations do
    Stations.Repo.all
    |> Enum.filter(fn station -> station.has_fare_machine end)
    |> Enum.map(
      fn station ->
        Phoenix.HTML.safe_to_string(link(station.name, to: station_path(Site.Endpoint, :show, station.id)))
      end)
    |> Enum.join(", ")
  end
end
