defmodule Alerts.Match do
  @doc """

  Returns the alerts which match the provided InformedEntity.

  """

  alias Alerts.InformedEntity, as: IE
  def match(alerts, entity) do
    alerts
    |> Enum.filter(&(any_entity_match?(&1, entity)))
  end

  defp any_entity_match?(alert, entity) do
    alert.informed_entity
    |> Enum.any?(&(IE.match?(&1, entity)))
  end
end
