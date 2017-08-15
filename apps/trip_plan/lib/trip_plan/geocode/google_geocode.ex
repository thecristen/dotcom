defmodule TripPlan.Geocode.GoogleGeocode do
  @behaviour TripPlan.Geocode

  alias TripPlan.NamedPosition

  @impl true
  def geocode(address) when is_binary(address) do
    case GoogleMaps.Geocode.geocode(address) do
      {:ok, [result]} ->
        {:ok, address_to_result(result)}
      {:ok, results} ->
        {:error, {:multiple_results, Enum.map(results, &address_to_result/1)}}
      {:error, :zero_results} ->
        {:error, :no_results}
      _ ->
        {:error, :unknown}
    end
  end

  defp address_to_result(%GoogleMaps.Geocode.Address{} = address) do
    %NamedPosition{
      name: address.formatted,
      latitude: address.latitude,
      longitude: address.longitude
    }
  end
end
