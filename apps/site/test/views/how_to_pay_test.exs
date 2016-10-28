defmodule Site.HowToPayViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.HowToPayView

  test "mode_template/1 finds the correct template to render" do
    assert mode_template(:the_ride) == "the_ride.html"
    assert mode_template(:bus) == "bus.html"
    assert mode_template(:commuter) == "commuter.html"
    assert mode_template(:subway) == "subway.html"
    assert mode_template(:ferry) == "ferry.html"
  end

  test "mode_string/1 converts the atom to a dash delimted string" do
    assert mode_string(:the_ride) == "the-ride"
    assert mode_string(:bus) == "bus"
    assert mode_string(:subway) == "subway"
    assert mode_string(:commuter) == "commuter"
    assert mode_string(:ferry) == "ferry"
  end
end
