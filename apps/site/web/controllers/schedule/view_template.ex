defmodule Site.ScheduleController.ViewTemplate do
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{route: %{type: route_type},
                        schedules: schedules}} = conn, []) do
    conn
    |> assign(:list_group_template, list_group_template(schedules, route_type))
  end

  defp list_group_template([], _), do: "empty.html"
  defp list_group_template([{_, _} | _], _), do: "pairs.html"
  defp list_group_template(_, 0), do: "subway.html"
  defp list_group_template(_, 1), do: "subway.html"
  defp list_group_template(_, 2), do: "rail.html"
  defp list_group_template(_, 3), do: "bus.html"
  defp list_group_template(_, 4), do: "rail.html"
end
