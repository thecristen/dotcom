defprotocol Stops.Position do
  @doc "The latitude of the item"
  def latitude(item)

  @doc "The longitude of the item"
  def longitude(item)
end

defimpl Stops.Position, for: Map do
  def latitude(%{latitude: latitude}), do: latitude
  def longitude(%{longitude: longitude}), do: longitude
end

defimpl Stops.Position, for: Tuple do
  def latitude({latitude, _}), do: latitude
  def longitude({_, longitude}), do: longitude
end
