defmodule Site.ScheduleController.Defaults do
  @moduledoc """
  For a given %Plug.Conn, assign some default values based on the query
  parameters.
  """
  import Plug.Conn
  use Timex

  import Util

  def init([]), do: []

  def call(conn, []) do
    conn
    |> index_params
    |> Enum.reduce(conn, fn {key, value}, conn -> assign(conn, key, value) end)
  end

  defp index_params(%{params: params} = conn) do
    direction_id = default_direction_id(conn)

    show_all_schedules = params["all_schedules"] != nil || not Timex.equal?(service_date, conn.assigns.date)

    show_full_list = params["full_list"] != nil

    [
      show_all_schedules: show_all_schedules,
      show_full_list: show_full_list,
      direction_id: direction_id,
      origin: case params["origin"] do
                "" -> nil
                value -> value
              end,
      destination: case params["dest"] do
                     "" -> nil
                     value -> value
                   end,
    ]
  end

  defp default_direction_id(%{params: %{"direction_id" => direction_str}}) when is_binary(direction_str) do
    case Integer.parse(direction_str) do
      {0, ""} -> 0
      {1, ""} -> 1
      _ -> default_direction_id(nil) # fallback to the default
    end
  end
  # if there's no headsign for a direction, default to the other direction
  defp default_direction_id(%{assigns: %{headsigns: %{0 => []}}}) do
    1
  end
  defp default_direction_id(%{assigns: %{headsigns: %{1 => []}}}) do
    0
  end
  defp default_direction_id(_) do
    if Util.now.hour <= 13 do
      1 # Inbound
    else
      0
    end
  end
end
