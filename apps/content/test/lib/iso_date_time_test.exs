defmodule Content.IsoDateTimeTest do
  use ExUnit.Case, async: true
  import Content.IsoDateTime

  describe "utc_date_time/1" do
    test "returns the start time formatted as an ISO date time in UTC" do
      date = "March 20, 2017"
      time = "10:00 AM"
      timezone = "America/New_York"

      expected_date_time = DateTime.from_naive!(~N[2017-03-20 14:00:00], "Etc/UTC")
      assert utc_date_time(date, time, timezone) == expected_date_time
    end
  end

  describe "parse_start_time/1" do
    test "returns the start time for a time range" do
      time = "10:00 AM - 12:00 PM"
      assert {:ok, "10:00 AM"} = parse_start_time(time)
    end

    test "returns the provided time, given only one time" do
      time = "10:00 AM"
      assert {:ok, "10:00 AM"} = parse_start_time(time)
    end

    test "returns an error, given a start time is not provided" do
      expected = {:error, "Expected a single time or time range."}
      assert parse_start_time("") == expected
    end
  end

  describe "parse_end_time/1" do
    test "returns the end time for a time range" do
      time = "10:00 AM - 12:00 PM"
      assert {:ok, "12:00 PM"} = parse_end_time(time)
    end

    test "returns an error, given an end time is not provided" do
      time = "10:00 AM"

      expected = {:error, "Expected a time range with an end time."}
      assert parse_end_time(time) == expected
    end
  end
end
