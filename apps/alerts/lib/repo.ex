defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  def all do
    cache [], fn _ ->
      V3Api.Alerts.all.data
      |> Enum.map(&Alerts.Parser.parse/1)
      |> Enum.map(&include_parents/1)
    end
  end

  def by_id(id) do
    all
    |> Enum.find(&(&1.id == id))
  end

  defp include_parents(alert) do
    # For alerts which are tied to a child stop, look up the parent stop and
    # also include it as an informed entity.
    %{alert |
      informed_entity: Enum.flat_map(alert.informed_entity, &include_ie_parents/1)
    }
  end

  defp include_ie_parents(%{stop: nil} = ie) do
    [ie]
  end

  defp include_ie_parents(%{stop: stop_id} = ie) do
    stop_id
    |> stop_ids
    |> Enum.map(&(%{ie | stop: &1}))
  end

  defp stop_ids(stop_id) do
    ConCache.get_or_store(:alerts_parent_ids, stop_id, fn ->
      case V3Api.Stops.by_gtfs_id(stop_id) do
        %JsonApi{
          data: [
            %JsonApi.Item{
              relationships: %{
                "parent_station" => [%JsonApi.Item{id: parent_id}]}}]} ->
          [stop_id, parent_id]
        _ -> [stop_id]
      end
    end)
  end
end
