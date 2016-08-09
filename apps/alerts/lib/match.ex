defmodule Alerts.Match do
  @doc """

  Returns the alerts which match the provided InformedEntity.

  """
  use Timex

  alias Alerts.InformedEntity, as: IE
  def match(alerts, entity, datetime \\ nil)
  def match(alerts, entity, nil) do
    alerts
    |> Enum.filter(&(any_entity_match?(&1, entity)))
  end
  def match(alerts, entity, datetime) do
    alerts
    |> match(entity, nil)
    |> Enum.filter(&(any_time_match?(&1, datetime)))
  end

  defp any_entity_match?(alert, entity) do
    alert.informed_entity
    |> Enum.any?(&(IE.match?(&1, entity)))
  end

  def any_time_match?(alert, datetime) do
    alert.active_period
    |> Enum.any?(&(between?(&1, datetime)))
  end

  defp between?({start, nil}, datetime) do
    Timex.equal?(datetime, start) || Timex.after?(datetime, start)
  end
  defp between?({nil, stop}, datetime) do
    Timex.equal?(datetime, stop) || Timex.before?(datetime, stop)
  end
  defp between?({start, stop}, datetime) do
    Timex.between?(datetime, start, stop) ||
      Timex.equal?(datetime, start) ||
      Timex.equal?(datetime, stop)
  end
end
