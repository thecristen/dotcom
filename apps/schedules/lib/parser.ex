defmodule Schedules.Parser do
  def parse(item) do
    %Schedules.Schedule{
      route: route(item),
      trip: trip(item),
      stop: stop(item),
      time: time(item)
    }
  end

  def route(
    %JsonApi.Item{
      relationships: %{
        "trip" => [
        %JsonApi.Item{
          relationships: %{
            "route" => [
            %JsonApi.Item{id: id,
                          attributes: %{"long_name" => long_name,
                                        "type" => type} = attributes}
            | _]
          }} | _]
      }
    }) do
    %Routes.Route{
      id: id,
      type: type,
      name: case long_name do
              "" -> attributes["short_name"]
              _ -> long_name
            end
    }
  end

  defp trip(%JsonApi.Item{
        relationships: %{
          "trip" => [%JsonApi.Item{id: id,
                                   attributes: %{"name" => name,
                                                 "headsign" => headsign}}]
        }}) do
    %Schedules.Trip{
      id: id,
      headsign: headsign,
      name: name
    }
  end

  def stop(%JsonApi.Item{
        relationships: %{
          "stop" => [
          %JsonApi.Item{
            id: id,
            attributes: %{
              "name" => name
            }}]
        }}) do
    %Schedules.Stop{
      id: id,
      name: name
    }
  end

  defp time(%JsonApi.Item{attributes: %{"departure_time" => departure_time}}) do
    departure_time
    |> Timex.parse!("{ISO}")
  end
end
