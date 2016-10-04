defmodule Site.ViewHelpersTest do
  use ExUnit.Case, async: true

  import Site.ViewHelpers
  alias Routes.Route

  describe "route_header_text/2" do
    test "translates the type number to a string" do
      assert route_header_text(%Route{type: 0, name: "test route"}) == "test route"
      assert route_header_text(%Route{type: 3, name: "2"}) == "Route 2"
      assert route_header_text(%Route{type: 1, name: "Red Line"}) == "Red Line"
      assert route_header_text(%Route{type: 2, name: "Fitchburg Line"}) == "Fitchburg"
    end
  end
end
