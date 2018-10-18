defmodule SiteWeb.VehicleChannelTest do
  use SiteWeb.ChannelCase

  alias SiteWeb.VehicleChannel

  test "sends vehicles and marker data" do
    assert {:ok, _, socket} =
      ""
      |> socket(%{some: :assign})
      |> subscribe_and_join(VehicleChannel, "vehicles:Red:0")

    assert [vehicle | _] = Vehicles.Repo.route("Red")

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
