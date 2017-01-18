defmodule Site.ScheduleV2Controller.Offset do
  @moduledoc """
  Assigns the offset parameter to determine which scheduled trips to show.
  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    assign(conn, :offset, find_offset(conn))
  end

  defp find_offset(%Plug.Conn{params: %{"offset" => offset}}) do
    case Integer.parse(offset) do
      {integer_offset, ""} -> integer_offset
      _ -> 0
    end
  end
  defp find_offset(%Plug.Conn{assigns: %{timetable_schedules: timetable_schedules, date_time: date_time}}) do
    timetable_schedules
    |> last_stop_schedules
    |> Enum.find_index(&Timex.after?(&1.time, date_time))
    |> Kernel.||(0)
  end

  defp last_stop_schedules(timetable_schedules) do
    timetable_schedules
    |> Enum.reverse
    |> Enum.uniq_by(& &1.trip)
    |> Enum.reverse
  end

end
