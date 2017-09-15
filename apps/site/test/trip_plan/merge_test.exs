defmodule Site.TripPlan.MergeTest do
  use ExUnit.Case, async: true
  use Quixir

  import Site.TripPlan.Merge

  doctest Site.TripPlan.Merge

  defp do_merge(first, second) do
    first = Enum.uniq(first)
    second = Enum.uniq(second)
    merged = merge(first, second, &==/2)
    {first, second, merged}
  end

  describe "merge/3" do
    test "includes no duplicates" do
      ptest first: list(of: positive_int(), max: 5), second: list(of: positive_int(), max: 5) do
        {_, _, merged} = do_merge(first, second)
        assert Enum.uniq(merged) == merged
      end
    end

    test "includes no more than total items" do
      ptest first: list(of: positive_int()), second: list(of: positive_int()), total: positive_int() do
        merged = merge(first, second, &==/2, total: total)
        assert length(merged) <= total
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
