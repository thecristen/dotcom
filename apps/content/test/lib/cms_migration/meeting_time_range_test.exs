 defmodule Content.CmsMigration.MeetingTimeRangeTest do
  use ExUnit.Case, async: true
  import Content.CmsMigration.MeetingTimeRange

  describe "parse_start_time/1" do
    test "returns the start time for a time range" do
      time = "10:00AM-12:00PM"
      assert parse_start_time(time) == "10:00AM"
    end

    test "given one time is provided" do
      time = "10:00AM"
      assert parse_start_time(time) == "10:00AM"
    end

    test "returns an error, given a start time is not provided" do
      expected = {:error, "Expected a single time or time range."}
      assert parse_start_time("") == expected
    end
  end

  describe "parse_end_time/2" do
    test "returns the end time for a time range" do
      time = "10:00AM-12:00PM"
      assert parse_end_time(time) == "12:00PM"
    end

    test "returns an error, given an end time is not provided" do
      time = "10:00AM"

      expected = {:error, "Expected a time range with an end time."}
      assert parse_end_time(time) == expected
    end
  end

  describe "standardize_format/1" do
    test "formats various time ranges to a consistent format" do
      assert standardize_format("2:00 PM - 4:00 PM    ") == "2:00PM-4:00PM"
      assert standardize_format("2:00 PM - 4:00 PM") == "2:00PM-4:00PM"
      assert standardize_format("2:00 PM to 4:00 PM") == "2:00PM-4:00PM"
      assert standardize_format("2:00 PM TO 4:00 PM") == "2:00PM-4:00PM"
      assert standardize_format("2:00PM - 4:00PM") == "2:00PM-4:00PM"
      assert standardize_format("2:00p.m. - 4:00p.m.") == "2:00PM-4:00PM"
      assert standardize_format("2:00 PM \u2013 4:00 PM") == "2:00PM-4:00PM"
      assert standardize_format("0200 PM - 1200 PM") == "0200PM-1200PM"
    end

    test "infers missing AM/PM values for the start time from the end time" do
      assert standardize_format("4:00 - 6:00 PM") == "4:00PM-6:00PM"
      assert standardize_format("6:30 -  8:30 PM") == "6:30PM-8:30PM"
      assert standardize_format("6:00 - 8:00  PM") == "6:00PM-8:00PM"
      assert standardize_format("12:00 - 3:00 p.m.") == "12:00PM-3:00PM"
    end

    test "when the missing AM/PM value cannot be inferred from the end_time" do
      assert standardize_format("6:00 - 8:00") == "6:00-8:00"
    end

    test "returns an error when unable to standardize the time range" do
      time_range = "2:00 PM - 4:00 PM, 6:00 PM - 8:00 PM"

      error = {:error, "Unable to standardize time range: 2:00PM4:00PM6:00PM8:00PM."}
      assert ^error = standardize_format(time_range)
    end
  end
end
