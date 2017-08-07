defmodule Site.EventDateRangeTest do
  use ExUnit.Case
  alias Site.EventDateRange

  describe "build/2" do
    test "returns a date range for the given a month" do
      params = %{"month" => "2017-02-01"}
      current_month = ~D[2017-04-15]

      assert EventDateRange.build(params, current_month) == %{
        start_time_gt: "2017-02-01",
        start_time_lt: "2017-03-01"
      }
    end

    test "returns a date range for upcoming events when a month is not provided" do
      current_month = ~D[2017-04-15]

      assert EventDateRange.build(%{}, current_month) == %{
        start_time_gt: "2017-04-15",
        start_time_lt: "2017-05-15"
      }
    end

    test "returns a date range for upcoming events when given an invalid date" do
      params = %{"month" => "nope"}
      current_month = ~D[2017-04-15]

      assert EventDateRange.build(params, current_month) == %{
        start_time_gt: "2017-04-15",
        start_time_lt: "2017-05-15"
      }
    end

    test "returns a date range for upcoming events when given a partial date" do
      params = %{"month" => "2017-01"}
      current_month = ~D[2017-04-15]

      assert EventDateRange.build(params, current_month) == %{
        start_time_gt: "2017-04-15",
        start_time_lt: "2017-05-15"
      }
    end
  end

  describe "for_month/1" do
    test "returns query params for the beginning and end of the given month" do
      date = ~D[2017-04-10]

      assert EventDateRange.for_month(date) == %{
        start_time_gt: "2017-04-01",
        start_time_lt: "2017-05-01"
      }
    end
  end
end
