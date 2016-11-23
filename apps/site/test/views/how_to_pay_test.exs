defmodule Site.HowToPayViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.HowToPayView

  test "mode_template/1 finds the correct template to render" do
    assert mode_template(:the_ride) == "the_ride.html"
    assert mode_template(:bus) == "bus.html"
    assert mode_template(:commuter_rail) == "commuter_rail.html"
    assert mode_template(:subway) == "subway.html"
    assert mode_template(:ferry) == "ferry.html"
  end
end
