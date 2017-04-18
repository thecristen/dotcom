defmodule Stops.StationInfo.CsvTest do
  use ExUnit.Case, async: true

  import Stops.StationInfo.Csv

  defp lines do
    "priv/stations.csv"
    |> File.stream!
    |> CSV.decode(headers: true)
  end

  describe "parse_row/1" do
    test "builds parking lot entries" do
      for line <- lines(),
        stop = parse_row(line),
        lot <- stop.parking_lots do
          refute lot.manager.name == ""
          refute lot.manager.name == "N/A"
          refute lot.rate == ""
          refute lot.rate == "N/A"
          for spot <- lot.spots do
            assert spot.type in ["basic", "accessible", "bike"]
            refute spot.spots == 0
          end
      end
    end

    test "builds accessibility entries" do
      accessibilities = for line <- lines(),
        stop = parse_row(line),
        accessibility <- stop.accessibility do
          accessibility
      end
      assert Enum.sort(Enum.uniq(accessibilities)) == [
        "accessible", "elevator",
        "escalator_both", "escalator_down", "escalator_up",
        "mini_high", "mobile_lift", "ramp", "tty_phone"
      ]
    end
  end
end
