defmodule Alerts.Match do
  @moduledoc """

  Returns the alerts which match the provided InformedEntity or entities.

  Passing multiple entities will allow the matching to be more efficient.

  """
  use Timex

  alias Alerts.InformedEntitySet, as: IESet

  def match(alerts, entity, datetime \\ nil)
  def match(alerts, entity, nil) do
    for alert <- alerts,
      any_entity_match?(alert, entity) do
        alert
    end
  end
  def match(alerts, entity, datetime) do
    # time first in order to minimize the more-expensive entity match
    for alert <- alerts,
      any_time_match?(alert, datetime),
      any_entity_match?(alert, entity) do
        alert
    end
  end

  defp any_entity_match?(alert, entities) when is_list(entities) do
    Enum.any?(entities, &any_entity_match?(alert, &1))
  end
  defp any_entity_match?(alert, entity) do
    IESet.match?(alert.informed_entity, entity)
  end

  def any_time_match?(alert, datetime) do
    alert.active_period
    |> Enum.any?(&between?(&1, datetime))
  end

  defp between?({nil, nil}, _) do
    true
  end
  defp between?({start, nil}, datetime) do
    compare(datetime, start) != :lt
  end
  defp between?({nil, stop}, datetime) do
    compare(datetime, stop) != :gt
  end
  defp between?({start, stop}, datetime) do
    compare(datetime, start) != :lt and
    compare(datetime, stop) != :gt
  end

  defp compare(%Date{} = first, %DateTime{} = second) do
    Date.compare(first, DateTime.to_date(second))
  end
  defp compare(%DateTime{} = first, %DateTime{} = second) do
    DateTime.compare(first, second)
  end
  defp compare(%NaiveDateTime{} = first, %NaiveDateTime{} = second) do
    NaiveDateTime.compare(first, second)
  end
end
