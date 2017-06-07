defmodule Alerts.Alert do
  defstruct [
    id: "",
    header: "",
    informed_entity: [],
    active_period: [],
    effect: :unknown,
    severity: :unknown,
    lifecycle: :unknown,
    updated_at: Timex.now(),
    description: ""
  ]
  @type period_pair :: {DateTime.t | nil, DateTime.t | nil}
  @type effect ::
  :amber_alert |
  :cancellation |
  :delay |
  :suspension |
  :track_change |
  :detour |
  :shuttle |
  :stop_closure |
  :dock_closure |
  :station_closure |
  :stop_moved |
  :extra_service |
  :schedule_change |
  :service_change |
  :snow_route |
  :station_issue |
  :dock_issue |
  :access_issue |
  :policy_change |
  :unknown
  @type severity :: :information | :minor | :moderate | :significant | :severe | :unknown
  @type lifecycle :: :ongoing | :upcoming | :ongoing_upcoming | :new | :unknown
  @type t :: %Alerts.Alert{
    id: String.t,
    header: String.t,
    informed_entity: [Alerts.InformedEntity.t],
    active_period: [period_pair],
    effect: effect,
    severity: severity,
    lifecycle: lifecycle,
    updated_at: DateTime.t,
    description: String.t
  }

  use Timex

  @ongoing_effects [
    :shuttle,
    :stop_closure,
    :snow_route,
    :cancellation,
    :detour,
    :no_service,
    :service_change
  ]

  @doc "Returns true if the Alert should be displayed as a less-prominent notice"
  @spec is_notice?(t, DateTime.t | Date.t) :: boolean
  def is_notice?(alert_list, time_or_date)
  def is_notice?(%__MODULE__{effect: :delay}, _) do
    # Delays are never notices
    false
  end
  def is_notice?(%__MODULE__{effect: :suspension}, _) do
    # Suspensions are not notices
    false
  end
  def is_notice?(%__MODULE__{effect: :access_issue}, _) do
    true
  end
  def is_notice?(%__MODULE__{effect: :service_change, severity: :minor}, _) do
    # minor service changes are never alerts
    true
  end
  def is_notice?(%__MODULE__{effect: effect, lifecycle: lifecycle}, _)
  when effect in @ongoing_effects and lifecycle in [:ongoing, :ongoing_upcoming] do
    # Ongoing alerts are notices
    true
  end
  def is_notice?(%__MODULE__{effect: effect} = alert, dt) when effect in @ongoing_effects do
    # non-Ongoing alerts are notices if they aren't happening now
    !Alerts.Match.any_time_match?(alert, dt)
  end
  def is_notice?(%__MODULE__{}, _) do
    # Default to true
    true
  end

  @doc "Returns a friendly name for the alert's effect"
  @spec human_effect(t) :: String.t
  def human_effect(%__MODULE__{effect: effect}) do
    do_human_effect(effect)
  end

  defp do_human_effect(:amber_alert), do: "Amber Alert"
  defp do_human_effect(:cancellation), do: "Cancellation"
  defp do_human_effect(:delay), do: "Delay"
  defp do_human_effect(:suspension), do: "Suspension"
  defp do_human_effect(:track_change), do: "Track Change"
  defp do_human_effect(:detour), do: "Detour"
  defp do_human_effect(:shuttle), do: "Shuttle"
  defp do_human_effect(:stop_closure), do: "Stop Closure"
  defp do_human_effect(:dock_closure), do: "Dock Closure"
  defp do_human_effect(:station_closure), do: "Station Closure"
  defp do_human_effect(:stop_moved), do: "Stop Move"
  defp do_human_effect(:extra_service), do: "Extra Service"
  defp do_human_effect(:schedule_change), do: "Schedule Change"
  defp do_human_effect(:service_change), do: "Service Change"
  defp do_human_effect(:snow_route), do: "Snow Route"
  defp do_human_effect(:station_issue), do: "Station Issue"
  defp do_human_effect(:dock_issue), do: "Dock Issue"
  defp do_human_effect(:access_issue), do: "Access Issue"
  defp do_human_effect(:policy_change), do: "Policy Change"
  defp do_human_effect(_), do: "Unknown"

  @doc "Returns a friendly name for the alert's lifecycle"
  @spec human_lifecycle(t) :: String.t
  def human_lifecycle(%__MODULE__{lifecycle: lifecycle}) do
    do_human_lifecycle(lifecycle)
  end

  defp do_human_lifecycle(:new), do: "New"
  defp do_human_lifecycle(:upcoming), do: "Upcoming"
  defp do_human_lifecycle(:ongoing_upcoming), do: "Upcoming"
  defp do_human_lifecycle(:ongoing), do: "Ongoing"
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
