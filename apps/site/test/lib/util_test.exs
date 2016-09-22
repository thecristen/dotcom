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
end
