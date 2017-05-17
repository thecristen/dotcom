defmodule Schedules.Parser do
  def parse(item) do
    %Schedules.Schedule{
      route: route(item),
      trip: trip(item),
      stop: stop(item),
      time: time(item),
      flag?: flag?(item),
      pickup_type: pickup_type(item),
      stop_sequence: item.attributes["stop_sequence"] || 0
    }
  end

  def route(
    %JsonApi.Item{
      relationships: %{
        "trip" => [
        %JsonApi.Item{
          relationships: %{
            "route" => [route | _]
          }} | _]
      }
    }) do
    Routes.Parser.parse_route(route)
  end

  def trip(%JsonApi.Item{
        relationships: %{
          "trip" => [%JsonApi.Item{id: id,
                                   attributes: %{"name" => name,
                                                 "headsign" => headsign,
                                                 "direction_id" => direction_id}} | _]
        }}) do
    %Schedules.Trip{
      id: id,
      headsign: headsign,
      name: name,
      direction_id: direction_id
    }
  end
  def trip(%JsonApi{
        data: [%JsonApi.Item{
                  id: id, attributes: %{
                    "headsign" => headsign,
                    "name" => name,
                    "direction_id" => direction_id}}]
           }) do
    %Schedules.Trip{
      id: id,
      headsign: headsign,
      name: name,
      direction_id: direction_id
    }
  end

  def stop(%JsonApi.Item{
        relationships: %{
          "stop" => [
          %JsonApi.Item{id: id}
        ]}}) do
    Stops.Repo.get!(id)
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
end
