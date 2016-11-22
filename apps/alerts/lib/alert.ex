defmodule Alerts.Alert do
  defstruct [
    id: "",
    header: "",
    informed_entity: [],
    active_period: [],
    effect_name: "",
    severity: "",
    lifecycle: "",
    updated_at: nil,
    description: ""
  ]
  @type period_pair :: {DateTime.t, nil} | {nil, DateTime.t} | {DateTime.t, DateTime.t} | {nil, nil}
  @type t :: %Alerts.Alert{
    id: String.t,
    header: String.t,
    informed_entity: [Alerts.InformedEntity.t],
    active_period: [period_pair],
    effect_name: String.t,
    severity: String.t,
    lifecycle: String.t,
    updated_at: DateTime.t,
    description: String.t
  }

  use Timex

  @doc "Returns true if the Alert should be displayed as a less-prominent notice"
  @spec is_notice?(Alerts.Alert.t, DateTime.t | Date.t) :: boolean
  def is_notice?(alert_list, time_or_date)
  def is_notice?(%__MODULE__{effect_name: "Delay"}, _) do
    # Delays are never notices
    false
  end
  def is_notice?(%__MODULE__{effect_name: "Suspension"}, _) do
    # Suspensions are not notices
    false
  end
  def is_notice?(%__MODULE__{effect_name: "Access Issue"}, _) do
    true
  end
  def is_notice?(%__MODULE__{effect_name: "Service Change", severity: "Minor"}, _) do
    # minor service changes are never alerts
    true
  end
  for effect <- [
        "Shuttle",
        "Stop Closure",
        "Snow Route",
        "Cancellation",
        "Detour",
        "No Service",
        "Service Change"
                ] do
    def is_notice?(%__MODULE__{effect_name: unquote(effect), lifecycle: "Ongoing" <> _}, _) do
      # Ongoing alerts are notices
      true
    end
    def is_notice?(%__MODULE__{effect_name: unquote(effect)} = alert, dt) do
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
  @type t :: %Alerts.InformedEntity{
    route: String.t | nil,
    route_type: String.t | nil,
    stop: String.t | nil,
    trip: String.t | nil,
    direction_id: 0 | 1 | nil
  }

  alias __MODULE__, as: IE

  @doc """

  Given a keyword list (with keys matching our fields), returns a new
  InformedEntity.  Additional keys are ignored.

  """
  @spec from_keywords(list) :: %IE{}
  def from_keywords(options) do
    map = options
    |> Map.new
    |> Map.take(@fields)

    struct!(__MODULE__, map)
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
