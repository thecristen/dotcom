defmodule UtilTest do
  use ExUnit.Case, async: true
  use ExCheck
  import Util

  describe "most_frequent_value/1" do
    test "handles simple cases" do
      assert most_frequent_value([1]) == 1
      assert most_frequent_value([1, 1]) == 1
      assert most_frequent_value([2, 1, 1]) == 1
    end

    property "always returns an element from the list" do
      for_all l in non_empty(list(int())) do
        Enum.member?(l, most_frequent_value(l))
      end
    end

    property "count of most_frequent value is equal or greater than the count of other elements" do
      for_all l in non_empty(list(int())) do
        most_frequent_value = most_frequent_value(l)
        most_frequent_count = Enum.count(l, &(&1 === most_frequent_value))
        Enum.all?(l, fn value ->
          most_frequent_count >= Enum.count(l, &(&1 === value))
        end)
      end
    end
  end

  describe "now/1" do
    test "handles ambiguous UTC times by returning the earlier time" do
      for {time, expected} <- [
            {~N[2016-11-06T05:00:00], "2016-11-06T01:00:00-04:00"},
            {~N[2016-11-06T06:00:00], "2016-11-06T02:00:00-04:00"},
            {~N[2016-11-06T07:00:00], "2016-11-06T02:00:00-05:00"}
          ] do

          utc_fn = fn -> Timex.set(time, timezone: "UTC") end
          assert utc_fn |> now() |> Timex.format("{ISO:Extended}") == {:ok, expected}
      end
    end
  end

  describe "service_date/0" do
    test "returns the service date for the current time" do
      assert service_date() == service_date(now())
    end
  end

  describe "service_date/1" do
    test "returns the service date" do
      expected = ~D[2016-01-01]
      for time_str <- [
            "2016-01-01T03:00:00-04:00",
            "2016-01-01T12:00:00-04:00",
            "2016-01-02T02:59:59-04:00"] do
          date_time = Timex.parse!(time_str, "{ISO:Extended}")
          assert service_date(date_time) == expected
      end
    end
  end

  describe "interleave" do
    test "interleaves lists" do
      assert Util.interleave([1, 3, 5], [2, 4, 6]) == [1, 2, 3, 4, 5, 6]
    end

    test "handles empty lists" do
      assert Util.interleave([1, 2, 3], []) == [1, 2, 3]
      assert Util.interleave([], [1, 2, 3]) == [1, 2, 3]
    end

    test "handles lists of different lengths" do
      assert Util.interleave([1, 3], [2, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
      assert Util.interleave([1, 3, 5, 6], [2, 4]) == [1, 2, 3, 4, 5, 6]
    end
  end
end
