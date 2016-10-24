defmodule Fares.Format do
  alias Fares.Fare

  @doc "Formats the price of a fare as a traditional $dollar.cents value"
  @spec price(Fare.t) :: String.t
  def price(%Fare{cents: cents}) do
    "$#{Float.to_string(cents / 100, decimals: 2)}"
  end

  @doc "Formats the fare media (card, &c) as a string"
  @spec media(Fare.t) :: String.t
  def media(%Fare{pass_type: :charlie_card}), do: "CharlieCard"
  def media(%Fare{pass_type: :ticket}), do: "Ticket"
  def media(%Fare{pass_type: :mticket}), do: "mTicket App"
  def media(%Fare{pass_type: :card_or_ticket}), do: "CharlieCard or Ticket"
  def media(%Fare{pass_type: :cash_or_ticket}), do: "Ticket or Cash"
  def media(%Fare{pass_type: :senior_card}), do: "Senior CharlieCard or TAP ID"
  def media(%Fare{pass_type: :student_card}), do: "Student CharlieCard"

  @doc "Formats the customers that are served by the given fare: Adult / Student / Senior"
  @spec customers(Fare.t) :: String.t
  def customers(%Fare{reduced: :student}), do: "Student"
  def customers(%Fare{reduced: :senior_disabled}), do: "Senior & Disabilities"
  def customers(%Fare{}), do: "Adult"

  @doc "Friendly name for the given fare"
  @spec name(Fare.t) :: String.t
  def name(%Fare{name: :subway}), do: "Subway"
  def name(%Fare{name: :local_bus}), do: "Local Bus"
  def name(%Fare{name: :inner_express_bus}), do: "Inner Express Bus"
  def name(%Fare{name: :outer_express_bus}), do: "Outer Express Bus"
  def name(%Fare{name: {:zone, zone}}), do: "Zone #{zone}"
  def name(%Fare{name: {:interzone, zone}}), do: "Interzone #{zone}"
  def name(%Fare{name: :ferry_inner_harbor}), do: "Inner Harbor Ferry"
  def name(%Fare{name: :ferry_cross_harbor}), do: "Cross Harbor Ferry"
  def name(%Fare{name: :commuter_ferry}), do: "Commuter Ferry"
  def name(%Fare{name: :commuter_ferry_logan}), do: "Commuter Ferry to Logan Airport"
end
