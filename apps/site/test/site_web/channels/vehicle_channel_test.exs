defmodule SiteWeb.VehicleChannelTest do
  use SiteWeb.ChannelCase

  alias SiteWeb.VehicleChannel

  test "can be subscribed to" do
    assert {:ok, _, %Phoenix.Socket{}} =
      ""
      |> socket(%{some: :assign})
      |> subscribe_and_join(VehicleChannel, "vehicles:Red:0")
  end
end
