defmodule GoogleMaps.GeocodeTest do
  use ExUnit.Case, async: true
  import GoogleMaps.Geocode
  alias GoogleMaps.Geocode.Address

  describe "geocode/1" do
    test "returns an error for invalid addresses" do
      actual = geocode("234k-rw0e8r0kew5")
      assert {:error, :zero_results, _msg} = actual
    end

    test "returns :ok for valid responses" do
      actual = geocode("10 Park Plaza, Boston, MA 02210")
      assert {:ok, results} = actual
      refute results == []
      for result <- results do
        assert %GoogleMaps.Geocode.Address{} = result
      end
    end
  end

  describe "Address" do
    test "implements the Stops.Position protocol" do
      Protocol.assert_impl!(Stops.Position, Address)
      address = %Address{}
      assert Stops.Position.latitude(address) == address.latitude
      assert Stops.Position.longitude(address) == address.longitude
    end
  end
end
