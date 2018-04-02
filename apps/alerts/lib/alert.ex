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
  :access_issue |
  :amber_alert |
  :cancellation |
  :delay |
  :detour |
  :dock_issue |
  :dock_closure |
  :elevator_closure |
  :escalator_closure |
  :extra_service |
  :no_service |
  :policy_change |
  :service_change |
  :shuttle |
  :suspension |
  :station_closure |
  :stop_closure |
  :stop_moved |
  :schedule_change |
  :snow_route |
  :snow_route |
  :station_issue |
  :stop_shoveling |
  :summary |
  :track_change |
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
    :cancellation,
    :detour,
    :no_service,
    :service_change,
    :snow_route,
    :shuttle,
    :stop_closure,
    :stop_shoveling
  ]

  @all_types [
    :access_issue,
    :amber_alert,
    :delay,
    :dock_closure,
    :dock_issue,
    :extra_service,
    :elevator_closure,
    :escalator_closure,
    :policy_change,
    :schedule_change,
    :station_closure,
    :station_issue,
    :stop_moved,
    :summary,
    :suspension,
    :track_change,
    :unknown | @ongoing_effects]

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

  @spec all_types :: [effect]
  def all_types, do: @all_types

  defp ensure_entity_set(%{informed_entity: %Alerts.InformedEntitySet{}} = alert) do
    alert
  end
  defp ensure_entity_set(alert) do
    %{alert | informed_entity: Alerts.InformedEntitySet.new(alert.informed_entity)}
  end

  @doc """
  Reducer to determine if alert is urgent due to time.
  High-severity alert should always be an alert if any of the following are true:
    * updated in the last week
    * now is within a week of start date
    * now is within one week of end date
  """
  @spec is_urgent_alert?(__MODULE__.t, DateTime.t) :: boolean
  def is_urgent_alert?(%__MODULE__{severity: sev}, _time) when sev < 7 do
    false
  end
  def is_urgent_alert?(%__MODULE__{active_period: []}, %DateTime{}) do
    true
  end
  def is_urgent_alert?(%__MODULE__{} = alert, %DateTime{} = time) do
    within_one_week(time, alert.updated_at) || Enum.any?(alert.active_period, &is_urgent_period?(&1, alert, time))
  end

  @spec is_urgent_period?({DateTime.t | nil, DateTime.t | nil}, __MODULE__.t, DateTime.t) :: boolean
  def is_urgent_period?(_, %__MODULE__{severity: sev}, %DateTime{}) when sev < 7 do
    false
  end
  def is_urgent_period?({nil, nil}, %__MODULE__{}, %DateTime{}) do
    true
  end
  def is_urgent_period?({nil, %DateTime{} = until}, %__MODULE__{}, %DateTime{} = time) do
    within_one_week(until, time)
  end
  def is_urgent_period?({%DateTime{} = from, nil}, %__MODULE__{}, %DateTime{} = time) do
    within_one_week(time, from)
  end
  def is_urgent_period?({from, until}, alert, time) do
    is_urgent_period?({from, nil}, alert, time) || is_urgent_period?({nil, until}, alert, time)
  end

  def within_one_week(time_1, time_2) do
    diff = Timex.diff(time_1, time_2, :days)
    diff <= 6 && diff >= -6
  end

  @doc "Returns true if the Alert should be displayed as a less-prominent notice"
  @spec is_notice?(t, DateTime.t | Date.t) :: boolean
  def is_notice?(alert_list, time_or_date)
  def is_notice?(%__MODULE__{} = alert, %Date{} = date) do
    is_notice?(alert, Timex.to_datetime(date))
  end
  def is_notice?(%__MODULE__{effect: :delay}, _) do
    # Delays are never notices
    false
  end
  def is_notice?(%__MODULE__{effect: :suspension}, _) do
    # Suspensions are not notices
    false
  end
  def is_notice?(%__MODULE__{severity: sev} = alert, time) when sev >= 7 do
     !is_urgent_alert?(alert, time)
  end
  def is_notice?(%__MODULE__{effect: :access_issue}, _) do
    true
  end
  def is_notice?(%__MODULE__{effect: :cancellation, active_period: active_period}, time) do
    date = Timex.to_date(time)
    Enum.all?(active_period, &outside_date_range?(date, &1))
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

  @spec outside_date_range?(Date.t, {Date.t, Date.t}) :: boolean
  defp outside_date_range?(date, {nil, until}) do
    until_date = Timex.to_date(until)
    date > until_date
  end
  defp outside_date_range?(date, {from, nil}) do
    from_date = Timex.to_date(from)
    date < from_date
  end
  defp outside_date_range?(date, {from, until}) do
    from_date = Timex.to_date(from)
    until_date = Timex.to_date(until)
    (date < from_date) || (date > until_date)
  end

  def access_alert_types do
    [elevator_closure: "Elevator",
     escalator_closure: "Escalator",
     access_issue: "Other"
    ]
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
  defp do_human_effect(:elevator_closure), do: "Elevator Closure"
  defp do_human_effect(:escalator_closure), do: "Escalator Closure"
  defp do_human_effect(:policy_change), do: "Policy Change"
  defp do_human_effect(:summary), do: "Summary"
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
