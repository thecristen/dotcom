defmodule UtilTest do
  use ExUnit.Case, async: true
  use ExCheck

  describe "most_frequent_value/1" do
    test "handles simple cases" do
      assert Util.most_frequent_value([1]) == 1
      assert Util.most_frequent_value([1, 1]) == 1
      assert Util.most_frequent_value([2, 1, 1]) == 1
    end

    property "always returns an element from the list" do
      for_all l in non_empty(list(int)) do
        Enum.member?(l, Util.most_frequent_value(l))
      end
    end

    property "count of most_frequent value is equal or greater than the count of other elements" do
      for_all l in non_empty(list(int)) do
        most_frequent_value = Util.most_frequent_value(l)
        most_frequent_count = Enum.count(l, &(&1 === most_frequent_value))
        Enum.all?(l, fn value ->
          most_frequent_count >= Enum.count(l, &(&1 === value))
        end)
      end
    end
  end

  describe "service_date/0" do
    test "returns the service date for the current time" do
      assert Util.service_date == Util.service_date(Util.now)
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
          assert Util.service_date(date_time) == expected
      end
    end
  end
end
