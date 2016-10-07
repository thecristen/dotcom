defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.FareView

  test "makes a useful description of a fare" do
    fare = %Fare{cents: 1000, duration: :single_trip, name: :zone_6, pass_type: :ticket, reduced: nil}
    assert FareView.fare_description(fare) == "Zone 6 One Way"
  end
end
