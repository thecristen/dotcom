defmodule TripPlan.Geocode.GoogleGeocodeTest do
  use ExUnit.Case
  import Mock
  import TripPlan.Geocode.GoogleGeocode
  alias GoogleMaps.{Geocode, Geocode.Address}
  alias TripPlan.NamedPosition

  describe "geocode/1" do
    test "returns {:ok, %NamedPosition{}} if Google returns a single result" do
      with_geocode_mock {:ok, [%Address{formatted: "formatted", latitude: 1, longitude: -1}]}, fn ->
        assert {:ok, %NamedPosition{name: "formatted", latitude: 1, longitude: -1}} = geocode("formatted")
      end
    end

    test "returns {:error, :no_results} if there are no results or a :zero_results error" do
      with_geocode_mock {:ok, []}, fn ->
        assert {:error, :no_results} = geocode("formatted")
      end

      with_geocode_mock {:error, :zero_results, "No results returned."}, fn ->
        assert {:error, :no_results} = geocode("formatted")
      end
    end

    test "returns {:error, {:multiple_results, [...]}} if there are multiple results" do
      one = %Address{formatted: "one", latitude: 1, longitude: 1}
      two = %Address{formatted: "two", latitude: 2, longitude: 2}
      with_geocode_mock {:ok, [one, two]}, fn ->
        assert {:error, {:multiple_results, positions}} = geocode("formatted")
        assert [
          %NamedPosition{name: "one", latitude: 1, longitude: 1},
          %NamedPosition{name: "two", latitude: 2, longitude: 2}
        ] = positions
      end
    end

    test "returns {:error, :unknown} for other errors" do
      with_geocode_mock {:error, :request_denied, "Request denied."}, fn ->
        assert {:error, :unknown} = geocode("formatted")
      end
    end
  end

  defp with_geocode_mock(geocode_return, test_fn) do
    with_mock Geocode, [geocode: fn _address -> geocode_return end] do
      test_fn.()
    end
  end
end
