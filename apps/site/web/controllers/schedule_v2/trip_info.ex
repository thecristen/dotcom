defmodule Site.ScheduleV2Controller.TripInfo do
  @moduledoc """

  Assigns :trip_info to either a TripInfo struct or nil, depending on whether
  there's a trip we want to display.

  """
  @behaviour Plug
  alias Plug.Conn
  import Plug.Conn, only: [assign: 3]
  import Phoenix.Controller, only: [redirect: 2]
  import UrlHelpers, only: [update_url: 2]
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
  defp trip_id(%Conn{assigns: %{schedules: schedules, date_time: date_time}}) when schedules != [] do
    current_trip(schedules, date_time)
  end
  defp trip_id(%Conn{}) do
    nil
  end

  defp handle_trip(conn, selected_trip_id, opts) do
    case build_info(selected_trip_id, conn, opts) do
      {:error, _} ->
        url = update_url(conn, trip: nil, origin: nil, destination: nil)
        redirect conn, to: url
      info ->
        assign(conn, :trip_info, info)
    end
  end

  defp build_info(trip_id, conn, opts) do
    trip_id
    |> opts[:trip_fn].()
    |> TripInfo.from_list(
      collapse?: is_nil(conn.query_params["show_collapsed_trip_stops?"]),
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
