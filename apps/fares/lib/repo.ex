defmodule Fares.Repo.ZoneFares do
  def fare_info do
    filename = "priv/zone_fares.csv"

    filename
    |> File.stream!
    |> CSV.decode
    |> Enum.flat_map(&mapper/1)
  end

  @lint {Credo.Check.Refactor.ABCSize, false}
  def mapper(["commuter", zone, single_trip, single_trip_reduced, monthly | _]) do
    mode = :commuter
    [
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(single_trip)},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :single_trip,
        pass_type: :ticket,
        reduced: :student,
        cents: dollars_to_cents(single_trip_reduced)},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :single_trip,
        pass_type: :ticket,
        reduced: :senior_disabled,
        cents: dollars_to_cents(single_trip_reduced)},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :month,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(monthly)},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :month,
        pass_type: :mticket,
        reduced: nil,
        cents: round(String.to_float(monthly) * 100) - 1000},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :round_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: round(String.to_float(single_trip) * 2 * 100)},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :round_trip,
        pass_type: :ticket,
        reduced: :student,
        cents: round(String.to_float(single_trip_reduced) * 2 * 100)},
      %Fare{
        mode: mode,
        name: commuter_rail_fare_name(zone),
        duration: :round_trip,
        pass_type: :ticket,
        reduced: :senior_disabled,
        cents: round(String.to_float(single_trip_reduced) * 2 * 100)}
    ]
  end
  def mapper([
    "subway",
    charlie_card_price,
    ticket_price,
    day_reduced_price,
    month_reduced_price,
    day_pass_price,
    week_pass_price,
    month_pass_price
  ]) do
    [
      %Fare{
        mode: :subway,
        name: :subway_charlie_card,
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: nil,
        cents: dollars_to_cents(charlie_card_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_ticket,
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(ticket_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_student,
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: :student,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_senior,
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: :senior,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_student,
        duration: :month,
        pass_type: :charlie_card,
        reduced: :student,
        cents: dollars_to_cents(month_reduced_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_senior,
        duration: :month,
        pass_type: :charlie_card,
        reduced: :senior,
        cents: dollars_to_cents(month_reduced_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_link_pass,
        duration: :day,
        pass_type: :link_pass,
        reduced: nil,
        cents: dollars_to_cents(day_pass_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_link_pass,
        duration: :week,
        pass_type: :link_pass,
        reduced: nil,
        cents: dollars_to_cents(week_pass_price)
      },
      %Fare{
        mode: :subway,
        name: :subway_link_pass,
        duration: :month,
        pass_type: :link_pass,
        reduced: nil,
        cents: dollars_to_cents(month_pass_price)
      }
    ]
  end
  def mapper([
    mode,
    charlie_card_price,
    ticket_price,
    day_reduced_price,
    month_reduced_price,
    day_pass_price,
    week_pass_price,
    month_pass_price
  ]) when mode in ["local_bus", "inner_express_bus", "outer_express_bus"] do
    [
      %Fare{
        mode: :bus,
        name: :"#{mode}_charlie_card",
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: nil,
        cents: dollars_to_cents(charlie_card_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_ticket",
        duration: :single_trip,
        pass_type: :ticket,
        reduced: nil,
        cents: dollars_to_cents(ticket_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_student",
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: :student,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_senior",
        duration: :single_trip,
        pass_type: :charlie_card,
        reduced: :senior,
        cents: dollars_to_cents(day_reduced_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_student",
        duration: :month,
        pass_type: :charlie_card,
        reduced: :student,
        cents: dollars_to_cents(month_reduced_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_senior",
        duration: :month,
        pass_type: :charlie_card,
        reduced: :senior,
        cents: dollars_to_cents(month_reduced_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_link_pass",
        duration: :day,
        pass_type: :link_pass,
        reduced: nil,
        cents: dollars_to_cents(day_pass_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_link_pass",
        duration: :week,
        pass_type: :link_pass,
        reduced: nil,
        cents: dollars_to_cents(week_pass_price)
      },
      %Fare{
        mode: :bus,
        name: :"#{mode}_link_pass",
        duration: :month,
        pass_type: :link_pass,
        reduced: nil,
        cents: dollars_to_cents(month_pass_price)
      }
    ]
  end

  defp commuter_rail_fare_name(zone) do
    case String.split(zone, "_") do
      ["zone", zone] -> {:zone, String.upcase(zone)}
      ["interzone", zone] -> {:interzone, String.upcase(zone)}
    end
  end

  defp dollars_to_cents(dollars) do
    dollars
    |> String.to_float
    |> Kernel.*(100)
    |> round
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
