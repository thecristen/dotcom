defmodule SiteWeb.VehicleChannelTest do
  use SiteWeb.ChannelCase

  alias SiteWeb.VehicleChannel

  test "sends vehicles and marker data" do
    # subscribes to a random channel name to
    # avoid receiving real data in assert_push
    assert {:ok, _, socket} =
      ""
      |> socket(%{some: :assign})
      |> subscribe_and_join(VehicleChannel, "vehicles:VehicleChannelTest")

    assert [vehicle | _] =
      []
      |> Vehicles.Repo.fetch()
      |> Enum.reject(& &1.route_id == nil)

    assert {:noreply, %Phoenix.Socket{}} =
      SiteWeb.VehicleChannel.handle_out("data", %{data: [vehicle]}, socket)

    assert_push "data", vehicles

    assert %{data: [vehicle_with_marker]} = vehicles
    assert %{
      data: ^vehicle,
      marker: %GoogleMaps.MapData.Marker{}
    } = vehicle_with_marker
  end
end
