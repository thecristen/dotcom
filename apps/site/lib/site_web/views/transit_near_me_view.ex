defmodule SiteWeb.TransitNearMeView do
  use SiteWeb, :view
  alias GoogleMaps.Geocode.Address

  defp input_value({:ok, [%Address{formatted: address}]}) do
    address
  end

  defp input_value(_) do
    ""
  end
end
