defmodule Algolia.StopsTest do
  use ExUnit.Case, async: true

  describe "&all/0" do
    test "returns a list of all stops parsed into Algolia.Stop structs" do
      stops = Algolia.Stops.all()
      assert Enum.all?(stops, &match?(%Stops.Stop{}, &1))
    end
  end
end
