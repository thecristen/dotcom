defmodule Alerts.Alert do
  defstruct [
    id: "",
    header: "",
    informed_entity: %Alerts.InformedEntitySet{},
    active_period: [],
    effect: :unknown,
    severity: 5,
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
  :stop_shoveling |
  :station_issue |
  :dock_issue |
  :access_issue |
  :policy_change |
  :unknown
  @type severity :: 0..10
  @type lifecycle :: :ongoing | :upcoming | :ongoing_upcoming | :new | :unknown
  @type t :: %Alerts.Alert{
    id: String.t,
    header: String.t,
    informed_entity: Alerts.InformedEntitySet.t,
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
    :stop_shoveling,
    :cancellation,
    :detour,
    :no_service,
    :service_change
  ]

  def new(keywords \\ [])
  def new([]) do
    %__MODULE__{}
  end
  def new(keywords) do
    alert = struct!(__MODULE__, keywords)
    ensure_entity_set(alert)
  end

  def update(%__MODULE__{} = alert, keywords) do
    alert = struct!(alert, keywords)
    ensure_entity_set(alert)
  end

  defp ensure_entity_set(%{informed_entity: %Alerts.InformedEntitySet{}} = alert) do
    alert
  end
  defp ensure_entity_set(alert) do
    %{alert | informed_entity: Alerts.InformedEntitySet.new(alert.informed_entity)}
  end

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
  def is_notice?(%__MODULE__{effect: :service_change, severity: severity}, _) when severity <= 3 do
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

  @spec do_human_effect(effect) :: String.t
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
  defp do_human_effect(:stop_shoveling), do: "Snow Shoveling"
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

  @spec do_human_lifecycle(lifecycle) :: String.t
  defp do_human_lifecycle(:new), do: "New"
  defp do_human_lifecycle(:upcoming), do: "Upcoming"
  defp do_human_lifecycle(:ongoing_upcoming), do: "Upcoming"
  defp do_human_lifecycle(:ongoing), do: "Ongoing"
  defp do_human_lifecycle(_), do: "Unknown"
end
