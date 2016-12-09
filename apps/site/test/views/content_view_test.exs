defmodule Site.ContentViewTest do
  use ExUnit.Case, async: true

  import Site.ContentView

  describe "scaled_map_srcset/2" do
    test "returns a srcset for the scaled map sizes" do
      sizes = [{1, 2}, {5, 10}]
      urls = [
        {"1", map_url("address", 1, 2, 1)},
        {"2", map_url("address", 1, 2, 2)},
        {"5", map_url("address", 5, 10, 1)},
        {"10", map_url("address", 5, 10, 2)},
      ]
      assert scaled_map_srcset(sizes, "address") == Picture.srcset(urls)
    end
  end

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

  describe "shift_month_url/3" do
    test "without any params, returns shifted URLs for the current month" do
      today = Util.today
      previous = Timex.shift(today, months: -1)
      path = "/path"
      gt = Timex.format!(previous, "{ISOdate}")
      lt = Timex.format!(today, "{ISOdate}")

      actual = shift_month_url(%{request_path: path, params: %{}}, :field, -1)
      expected = ~s(/path?field_gt=#{gt}&field_lt=#{lt})

      assert expected == actual
    end

    test "with a param, shifts the gt and lt values by that much" do
      params = %{
        "field_gt" => "2016-12-01"
      }
      path = "/path"
      actual = shift_month_url(%{request_path: path, params: params}, :field, 1)
      expected = "/path?field_gt=2017-01-01&field_lt=2017-02-01"

      assert expected == actual
    end

    test "with an invalid param, works the same as if no params was passed" do
      path = "/path"
      actual = shift_month_url(%{request_path: path, params: %{"field_gt" => "invalid"}}, :field, 1)
      expected = shift_month_url(%{request_path: path, params: %{}}, :field, 1)

      assert expected == actual
    end
  end
end
