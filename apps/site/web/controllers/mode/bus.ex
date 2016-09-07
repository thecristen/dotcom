defmodule Site.Mode.BusController do
  use Site.Mode.HubBehaviour

  def route_type, do: 3

  def mode_name, do: "Bus"

  def fare_description do
    "For Inner and Outer Express Bus fares, read the complete Bus Fares page."
  end
end
