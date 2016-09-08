defmodule Site.ScheduleController.ViewTemplate do
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{route: %{type: route_type},
                        schedules: schedules}} = conn, []) do
    conn
    |> assign(:view_template, view_template(schedules))
    |> assign(:list_group_template, list_group_template(route_type))
  end

  defp view_template([]), do: "empty.html"
  defp view_template([{_, _} | _]), do: "pairs.html"
  defp view_template(_), do: "index.html"

  defp list_group_template(0), do: "subway.html"
  defp list_group_template(1), do: "subway.html"
  defp list_group_template(2), do: "rail.html"
  defp list_group_template(3), do: "bus.html"
  defp list_group_template(4), do: "rail.html"
end
