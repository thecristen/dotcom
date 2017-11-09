defmodule Schedules.Parser do
  def parse(item) do
    {
      route_id(item),
      trip_id(item),
      stop_id(item),
      time(item),
      flag?(item),
      item.attributes["stop_sequence"] || 0,
      pickup_type(item)
    }
  end

  def route_id(
    %JsonApi.Item{
      relationships: %{
        "route" => [%JsonApi.Item{id: id} | _]}}) do
    id
  end

  def trip_id(%JsonApi.Item{
        relationships: %{
          "trip" => [%JsonApi.Item{id: id} | _]}}) do
    id
  end

  def trip(%JsonApi.Item{
        relationships: %{
          "trip" => [%JsonApi.Item{id: id,
                                   attributes: %{"name" => name,
                                                 "headsign" => headsign,
                                                 "direction_id" => direction_id},
                                   relationships: relationships} | _]
        }}) do
    %Schedules.Trip{
      id: id,
      headsign: headsign,
      name: name,
      direction_id: direction_id,
      shape_id: shape_id(relationships)
    }
  end
  def trip(%JsonApi{
        data: [%JsonApi.Item{
                  id: id, attributes: %{
                    "headsign" => headsign,
                    "name" => name,
                    "direction_id" => direction_id},
                  relationships: relationships}]
           }) do
    %Schedules.Trip{
      id: id,
      headsign: headsign,
      name: name,
      direction_id: direction_id,
      shape_id: shape_id(relationships)
    }
  end
  def trip(%JsonApi.Item{
        relationships: %{
          "trip" => _}}) do
    nil
  end

  def stop_id(%JsonApi.Item{
        relationships: %{
          "stop" => [
          %JsonApi.Item{id: id}
        ]}}) do
    id
  end

  defp time(%JsonApi.Item{attributes: %{"departure_time" => departure_time}}) do
    departure_time
    |> Timex.parse!("{ISO:Extended}")
  end

  defp flag?(%JsonApi.Item{attributes: %{"pickup_type" => pickup_type,
                                         "drop_off_type" => drop_off_type}}) do
    # https://developers.google.com/transit/gtfs/reference/stop_times-file
    # defines pickup_type and drop_off_type:
    # * 0: Regularly scheduled drop off
    # * 1: No drop off available
    # * 2: Must phone agency to arrange drop off
    # * 3: Must coordinate with driver to arrange drop off
    # Flag trips are those which need coordination.
    pickup_type == 3 || drop_off_type == 3
  end

  defp pickup_type(%JsonApi.Item{attributes: %{"pickup_type" => pickup_type}}) do
    pickup_type
  end

  @spec shape_id(any) :: String.t | nil
  defp shape_id(%{"shape" => [%JsonApi.Item{id: id}]}), do: id
  defp shape_id(_), do: nil
end
