defmodule Content.CmsMigration.MeetingTest do
  use ExUnit.Case, async: true
  import Content.CmsMigration.Meeting

  describe "start_utc_datetime/2" do
    test "returns the meeting start time as a datetime" do
      date = "April 15, 2017"
      time_range = "4:00 PM - 6:00 PM"

      expected = Timex.to_datetime({{2017, 4, 15}, {20,0,0}}, "Etc/UTC")
      assert start_utc_datetime(date, time_range) == expected
    end

    test "when the start time cannot be determined" do
      date = "April 15, 2017"

      error = {:error, :invalid_time_range}
      assert ^error = start_utc_datetime(date, "")
    end
  end

  describe "end_utc_datetime/2" do
    test "returns the meeting end time as a datetime" do
      date = "April 15, 2017"
      time_range = "4:00 PM - 6:00 PM"

      expected = Timex.to_datetime({{2017, 4, 15}, {22,0,0}}, "Etc/UTC")
      assert end_utc_datetime(date, time_range) == expected
    end

    test "when the end time cannot be determined" do
      date = "April 15, 2017"

      error = {:error, :invalid_time_range}
      assert ^error = end_utc_datetime(date, "5:00PM")
    end
  end
end
