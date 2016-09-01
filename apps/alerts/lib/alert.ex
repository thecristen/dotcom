defmodule Alerts.Alert do
  defstruct [
    :id, :header, :informed_entity, :active_period, :effect_name, :severity, :lifecycle, :updated_at, :description
  ]

  use Timex

  @doc "Returns true if the Alert should be displayed as a less-prominent notice"
  @spec is_notice?(%__MODULE__{}) :: boolean
  def is_notice?(%__MODULE__{}=alert) do
    is_notice?(alert, Timex.now("America/New_York"))
  end
  def is_notice?(%__MODULE__{effect_name: "Delay"}, _) do
    # Delays are never notices
    false
  end
  def is_notice?(%__MODULE__{effect_name: "Suspension"}, _) do
    # Suspensions are not notices
    false
  end
  for effect <- ["Shuttle", "Stop Closure", "Snow Route", "Cancellation", "Detour", "No Service"] do
    def is_notice?(%__MODULE__{effect_name: unquote(effect), lifecycle: "Ongoing"}, _) do
      # Ongoing alerts are notices
      true
    end
    def is_notice?(%__MODULE__{effect_name: unquote(effect)}=alert, dt) do
      # non-Ongoing alerts are notices if they aren't happening now
      !Alerts.Match.any_time_match?(alert, dt)
    end
  end
  def is_notice?(%__MODULE__{}, _) do
    # Default to true
    true
  end
end

defmodule Alerts.InformedEntity do
  @fields [:route, :route_type, :stop, :trip, :direction_id]
  defstruct @fields

  alias __MODULE__, as: IE

  @spec put(%IE{}, :route|:route_type|:stop|:trip, any) :: %IE{}
  def put(entity, :route_type, value) do
    %Alerts.InformedEntity{entity | route_type: value}
  end
  def put(entity, :route, value) do
    %Alerts.InformedEntity{entity | route: value}
  end
  def put(entity, :stop, value) do
    %Alerts.InformedEntity{entity | stop: value}
  end
  def put(entity, :trip, value) do
    %Alerts.InformedEntity{entity | trip: value}
  end
  def put(entity, :direction_id, value) do
    %Alerts.InformedEntity{entity | direction_id: value}
  end

  @doc """

  Returns true if the two InformedEntities match.

  If a route/route_type/stop is specified (non-nil), it needs to equal the other.
  Otherwise the nil can match any value in the other InformedEntity.

  """
  @spec match?(%IE{}, %IE{}) :: boolean
  def match?(%IE{} = first, %IE{} = second) do
    share_a_key(first, second) && do_match?(first, second)
  end

  defp do_match?(f, s) do
    @fields
    |> Enum.all?(&do_key_match(Map.get(f, &1), Map.get(s, &1)))
  end

  defp do_key_match(eql, eql), do: true
  defp do_key_match(nil, _), do: true
  defp do_key_match(_, nil), do: true
  defp do_key_match(_, _), do: false

  defp share_a_key(first, second) do
    @fields
    |> Enum.any?(&shared_key(Map.get(first, &1), Map.get(second, &1)))
  end

  defp shared_key(nil, nil), do: false
  defp shared_key(eql, eql), do: true
  defp shared_key(_, _), do: false
end
