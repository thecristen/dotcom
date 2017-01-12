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
  defp find_offset(%Plug.Conn{assigns: %{all_schedules: all_schedules, date_time: date_time}}) do
    all_schedules
    |> Enum.find_index(&Timex.after?(&1.time, date_time))
    |> Kernel.||(0)
  end
end
