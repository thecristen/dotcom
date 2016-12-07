defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true

  import Site.ContentView

  describe "event_duration/2" do
    test "with no end time, only renders start time" do
      actual = event_duration(~N[2016-11-15T10:00:00], nil)
      expected = "Tuesday, November 15th 10:00 AM"
      assert expected == actual
    end

    test "with start/end on same day, only renders date once" do
      actual = event_duration(~N[2016-11-14T12:00:00], ~N[2016-11-14T14:30:00])
      expected = "Monday, November 14th 12:00 PM until 2:30 PM"
      assert expected == actual
    end

    test "with start/end on different days, renders both dates" do
      actual = event_duration(~N[2016-11-14T12:00:00], ~N[2016-12-01T14:30:00])
      expected = "Monday, November 14th 12:00 PM until Thursday, December 1st 2:30 PM"
      assert expected == actual
    end

    test "with DateTimes, shifts them to America/New_York" do
      actual = event_duration(
        Timex.to_datetime(~N[2016-11-05T05:00:00], "Etc/UTC"),
        Timex.to_datetime(~N[2016-11-06T06:00:00], "Etc/UTC"))
      # could also be November 6th, 1:00 AM
      expected = "Saturday, November 5th 1:00 AM until Sunday, November 6th 2:00 AM"
      assert expected == actual
    end
  end
end
