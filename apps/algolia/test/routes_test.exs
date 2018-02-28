defmodule Algolia.RoutesTest do
  use ExUnit.Case, async: true

  describe "Algolia.RoutesTest" do
    test "&all/0" do
      assert Enum.all?(Algolia.Routes.all(), &match?(%Routes.Route{}, &1))
    end
  end
end
