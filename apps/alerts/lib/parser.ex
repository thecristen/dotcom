defmodule Alerts.Parser do
  defmodule Alert do
    @spec parse(JsonApi.Item.t) :: Alerts.Alert.t
    def parse(%JsonApi.Item{type: "alert", id: id, attributes: attributes}) do
      %Alerts.Alert{
        id: id,
        header: attributes["header"],
        informed_entity: parse_informed_entity(attributes["informed_entity"]),
        active_period:  Enum.map(attributes["active_period"], &active_period/1),
        effect: effect(attributes),
        severity: severity(attributes["severity"]),
        lifecycle: lifecycle(attributes["lifecycle"]),
        updated_at: parse_time(attributes["updated_at"]),
        description: description(attributes["description"])
      }
    end

    defp parse_informed_entity(informed_entities) do
      informed_entities
      |> Enum.flat_map(&informed_entity/1)
      |> Enum.uniq()
    end

    defp informed_entity(%{"route" => "Green" <> _} = entity) do
      [do_informed_entity(entity), do_informed_entity(%{entity | "route" => "Green"})]
    end
    defp informed_entity(entity) do
      [do_informed_entity(entity)]
    end

    defp do_informed_entity(entity) do
      # since lookups default to nil, this results in the correct data
      %Alerts.InformedEntity{
        route_type: entity["route_type"],
        route: entity["route"],
        stop: entity["stop"],
        trip: entity["trip"],
        direction_id: entity["direction_id"]
      }
    end

    defp active_period(%{"start" => start, "end" => stop}) do
      {parse_time(start), parse_time(stop)}
    end

    defp parse_time(nil) do
      nil
    end
    defp parse_time(str) do
      str
      |> Timex.parse!("{ISO:Extended}")
    end

    # remove leading/trailing whitespace from description
    defp description(nil) do
      nil
    end
    defp description(str) do
      case String.trim(str) do
        "" -> nil
        str -> str
      end
    end

    @spec effect(%{String.t => String.t}) :: Alerts.Alert.effect
    defp effect(attributes) do
      case Map.fetch(attributes, "effect_name") do
        {:ok, effect_name} ->
          effect_name
          |> String.replace(" ", "_")
          |> String.upcase
          |> do_effect
        :error ->
          attributes
          |> Map.get("effect")
          |> do_effect
      end
    end

    defp do_effect("AMBER_ALERT"), do: :amber_alert
    defp do_effect("CANCELLATION"), do: :cancellation
    defp do_effect("DELAY"), do: :delay
    defp do_effect("SUSPENSION"), do: :suspension
    defp do_effect("TRACK_CHANGE"), do: :track_change
    defp do_effect("DETOUR"), do: :detour
    defp do_effect("SHUTTLE"), do: :shuttle
    defp do_effect("STOP_CLOSURE"), do: :stop_closure
    defp do_effect("DOCK_CLOSURE"), do: :dock_closure
    defp do_effect("STATION_CLOSURE"), do: :station_closure
    defp do_effect("STOP_MOVE"), do: :stop_moved # previous configuration
    defp do_effect("STOP_MOVED"), do: :stop_moved
    defp do_effect("EXTRA_SERVICE"), do: :extra_service
    defp do_effect("SCHEDULE_CHANGE"), do: :schedule_change
    defp do_effect("SERVICE_CHANGE"), do: :service_change
    defp do_effect("SNOW_ROUTE"), do: :snow_route
    defp do_effect("STATION_ISSUE"), do: :station_issue
    defp do_effect("DOCK_ISSUE"), do: :dock_issue
    defp do_effect("ACCESS_ISSUE"), do: :access_issue
    defp do_effect("POLICY_CHANGE"), do: :policy_change
    defp do_effect(_), do: :unknown

    @spec severity(String.t | integer) :: Alerts.Alert.severity
    def severity(binary) when is_binary(binary) do
      case String.upcase(binary) do
        "INFORMATION" -> 1
        "MINOR" -> 3
        "MODERATE" -> 5
        "SIGNIFICANT" -> 6
        "SEVERE" -> 7
        _ -> 5 # default to moderate
      end
    end
    def severity(int) when 0 <= int and int <= 10 do
      int
    end

    @spec lifecycle(String.t) :: Alerts.Alert.lifecycle
    def lifecycle(binary) do
      case String.upcase(binary) do
        "ONGOING" -> :ongoing
        "UPCOMING" -> :upcoming
        # could be either "ONGOING_UPCOMING" or "ONGOING UPCOMING"
        "ONGOING" <> _ -> :ongoing_upcoming
          "NEW" -> :new
        _ -> :unknown
      end
    end
  end

  defmodule Banner do
    @spec parse(JsonApi.Item.t) :: [Alerts.Banner.t]
    def parse(%JsonApi.Item{
          id: id,
          attributes: %{
            "url" => url,
            "banner" => title
          }}) when title != nil do
      [
        %Alerts.Banner{
          id: id,
          title: title,
          url: url}
      ]
    end
    def parse(%JsonApi.Item{}) do
      []
    end
  end
end
