defmodule Site.FareView do
  use Site.Web, :view

  alias Fares.Fare

  defdelegate description(fare), to: Site.FareView.Description

  def fare_duration_summary(:month) do
    "1 Month"
  end
  def fare_duration_summary(:round_trip) do
    "Round Trip"
  end
  def fare_duration_summary(:single_trip) do
    "Single Ride"
  end
  def fare_duration_summary(:day) do
    "1 Day"
  end
  def fare_duration_summary(:week) do
    "7 Days"
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

  @spec callout(Fare.t) :: String.t | iolist
  def callout(%Fare{name: :inner_express_bus}) do
    ["Travels on Routes: 170, 325, 326, 351, 424, 426, 428, 434, 449, 450, 459, 501, 502, 504, ",
     "553, 554 and 558."]
  end
  def callout(%Fare{name: :outer_express_bus}) do
    "Travels on routes: 352, 354, and 505."
  end
  def callout(%Fare{}), do: ""

  @spec vending_machine_stations :: [Phoenix.HTML.Safe.t]
  def vending_machine_stations do
    Stations.Repo.all
    |> Enum.filter(fn station -> station.has_fare_machine end)
    |> station_link_list
  end

  def charlie_card_stations do
    Stations.Repo.all
    |> Enum.filter(fn station -> station.has_charlie_card_vendor end)
    |> station_link_list
  end

  defp station_link_list(stations) do
    stations
    |> Enum.map(&station_link/1)
    |> Enum.intersperse(", ")
  end

  @spec update_fare_type(Plug.Conn.t, Fare.reduced) :: Plug.Conn.t
  def update_fare_type(conn, reduced_type) do
    update_url(conn, fare_type: reduced_type)
  end
end
