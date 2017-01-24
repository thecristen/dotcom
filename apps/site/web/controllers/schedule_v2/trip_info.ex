defmodule Site.ScheduleV2.TripInfo do
  @moduledoc """

  Assigns :trip_info to either a TripInfo struct or nil, depending on whether
  there's a trip we want to display.

  """
  @behaviour Plug
  alias Plug.Conn
  import Plug.Conn, only: [assign: 3]
  import Phoenix.Controller, only: [redirect: 2]
  alias Schedules.Schedule

  @default_opts [
    trip_fn: &Schedules.Repo.schedule_for_trip/1,
    vehicle_fn: &Vehicles.Repo.trip/1
  ]

  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  def call(conn, opts) do
    case trip_id(conn) do
      nil ->
        assign(conn, :trip_info, nil)
      selected_trip_id ->
        handle_trip(conn, selected_trip_id, opts)
    end
  end

  defp trip_id(%Conn{query_params: %{"trip" => trip_id}}) do
    trip_id
  end
  defp trip_id(%Conn{assigns: %{all_schedules: all_schedules, date_time: date_time}}) when all_schedules != [] do
    current_trip(all_schedules, date_time)
  end
  defp trip_id(%Conn{}) do
    nil
  end

  defp handle_trip(conn, selected_trip_id, opts) do
    case build_info(selected_trip_id, conn, opts) do
      {:error, _} ->
        url = Site.ScheduleV2View.update_schedule_url(conn, trip: nil, origin: nil, destination: nil)
        redirect conn, to: url
      info ->
        assign(conn, :trip_info, info)
    end
  end

  defp build_info(trip_id, conn, opts) do
    trip_id
    |> opts[:trip_fn].()
    |> TripInfo.from_list(
      show_between?: conn.query_params["show_between?"] != nil,
      vehicle: opts[:vehicle_fn].(trip_id),
      origin_id: conn.query_params["origin"],
      destination_id: conn.query_params["destination"])
  end

  # If there are more trips left in a day, finds the next trip based on the current time.
  @spec current_trip([Schedule.t | {Schedule.t, Schedule.t}], DateTime.t) :: String.t | nil
  defp current_trip([%Schedule{} | _] = schedules, now) do
    do_current_trip schedules, now
  end
  defp current_trip([{%Schedule{}, %Schedule{}} | _] = schedules, now) do
    schedules
    |> Enum.map(&(elem(&1, 0)))
    |> do_current_trip(now)
  end
  defp current_trip([], _now), do: nil

  @spec do_current_trip([Schedule.t], DateTime.t) :: String.t | nil
  defp do_current_trip(schedules, now) do
    case Enum.find(schedules, &is_after_now?(&1, now)) do
      nil -> nil
      schedule -> schedule.trip.id
    end
  end

  @spec is_after_now?(Schedule.t, DateTime.t) :: boolean
  defp is_after_now?(%Schedules.Schedule{time: time}, now) do
    Timex.after?(time, now)
  end
end
