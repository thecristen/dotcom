defmodule Util.EnumHelpersTest do
  use ExUnit.Case, async: true
  use ExCheck

  import EnumHelpers
  doctest EnumHelpers

  describe "with_first_last/1" do
    property "doesn't change the order" do
      for_all l in list(int()) do
        l == l |> with_first_last() |> Enum.map(&elem(&1, 0))
      end
    end

    property "puts a true for the first and last items" do
      for_all l in list(int()) do
        actual = with_first_last(l)
        case l do
          [] ->
            actual == []
          _ ->
            List.first(actual) == {List.first(l), true} &&
              List.last(actual) == {List.last(l), true} &&
              Enum.all?(Enum.slice(actual, 1..-2), &elem(&1, 1) == false)
        end
      end
    end
  end
end
