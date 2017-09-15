defmodule Site.TripPlan.MergeTest do
  use ExUnit.Case, async: true
  use Quixir

  import Site.TripPlan.Merge

  doctest Site.TripPlan.Merge

  defp id(x), do: x
  defp do_merge(first, second) do
    merged = merge(first, second, &id/1)
    {first, second, merged}
  end

  describe "merge/3" do
    test "includes no duplicates" do
      ptest first: list(of: positive_int(), max: 5), second: list(of: positive_int(), max: 5) do
        {_, _, merged} = do_merge(first, second)
        assert Enum.uniq(merged) == merged
      end
    end

    test "includes no more than 3 items" do
      ptest first: list(of: positive_int(), max: 5), second: list(of: positive_int(), max: 5) do
        {_, _, merged} = do_merge(first, second)
        assert length(merged) <= 3
      end
    end

    test "always includes the first two items of the lists" do
      ptest first: list(of: positive_int(), max: 5), second: list(of: positive_int(), max: 5) do
        {first, second, merged} = do_merge(first, second)
        unless first == [] do
          assert List.first(first) in merged
        end
        unless second == [] do
          assert List.first(second) in merged
        end
      end
    end
  end
end
