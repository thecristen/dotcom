defmodule TripPlan.Geocode.GoogleGeocode do
  @behaviour TripPlan.Geocode

  alias TripPlan.NamedPosition

  def geocode(address) do
    with {:ok, addresses} <- GoogleMaps.Geocode.geocode(address),
         results = Enum.map(addresses, &address_to_result/1),
         [result] <- results do
      {:ok, result}
    else
      [] ->
        {:error, :no_results}
      [_ | _] = results ->
        {:error, {:too_many_results, results}}
      {:error, :zero_results, _} ->
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
