defmodule Site.FareView do
  use Site.Web, :view

  alias Fares.Fare

  defdelegate description(fare), to: Site.FareView.Description

  def eligibility(%Fare{mode: mode, reduced: :student}) do
    "Middle and high school students are eligible for reduced fares on the #{Routes.Route.type_name(mode)}. \
In order to receive a reduced fare, students must use a Student CharlieCard issued by their school. \
One Way fares and Stored Value are eligible for the reduced rate, however 1-Day, 7-Day, and Monthly Passes are \
not. College students may be eligible for reduced fares through a Semester Pass Program. For more information, \
please contact an administrator at your school."
  end
  def eligibility(%Fare{mode: mode, reduced: :senior_disabled}) do
    "Those who are 65 years of age or older and persons with disabilities qualify for a reduced fare on the \
#{Routes.Route.type_name(mode)}. In order to receive a reduced fare, seniors must obtain a Senior CharlieCard and \
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
    AndJoin.and_join ~w(170 325 326 351 424 426 428 434 449 450 459 501 502 504
     553 554 558.)
  end
  def callout(%Fare{name: :outer_express_bus}) do
    AndJoin.and_join ~w(352 354 505.)
  end
  def callout(%Fare{}), do: ""

  def callout_description(%Fare{name: name}) when name == :outer_express_bus or name == :inner_express_bus do
    "Travels on Routes: "
  end
  def callout_description(%Fare{}), do: ""

  @spec vending_machine_stations :: [Phoenix.HTML.Safe.t]
  def vending_machine_stations do
    Stops.Repo.stations
    |> Enum.filter(fn stop -> stop.has_fare_machine? end)
    |> stop_link_list
  end

  def charlie_card_stations do
    Stops.Repo.stations
    |> Enum.filter(fn stop -> stop.has_charlie_card_vendor? end)
    |> stop_link_list
  end

  defp stop_link_list(stops) do
    stops
    |> Enum.map(&stop_link/1)
    |> Enum.intersperse(", ")
  end

  @spec update_fare_type(Plug.Conn.t, Fare.reduced) :: Plug.Conn.t
  def update_fare_type(conn, reduced_type) do
    update_url(conn, fare_type: reduced_type)
  end

  def fare_mode_icons(modes) do
    content_tag :span, class: "payment-method-modes" do
      for mode <- modes do
        svg_icon_with_circle(%SvgIconWithCircle{icon: mode, class: "icon-small"})
      end
    end
  end
end
