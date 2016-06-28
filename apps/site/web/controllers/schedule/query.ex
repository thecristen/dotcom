defmodule Site.ScheduleController.Query do
  @moduledoc """
  Given a conn, returns the relevant parameters for making a query
  of Schedules.Repo.all/1
  """
  def schedule_query(%Plug.Conn{params: params, assigns: assigns}) do
    route = params["route"]
    direction_id = assigns[:direction_id]

    schedule_params = [
      route: route,
      date: assigns[:date],
      direction_id: direction_id]

    case Map.get(params, "origin", default_origin(route, direction_id)) do
      "" ->
        schedule_params
        |> Keyword.put(:stop_sequence, "first")

     stop_id ->
        schedule_params
        |> Keyword.put(:stop, stop_id)

    end
  end

  # special cases for the subways so that they pick up all relevant headways
  # by default
  defp default_origin("Red", 1) do
    "70084" # Andrew
  end
  defp default_origin("Blue", 0) do
    "70051" # Orient Heights - Inbound
  end
  defp default_origin("Orange", 0) do
    "70036" # Oak Grove
  end
  defp default_origin("Green-D", 0) do
    "70202" # Government Center
  end
  defp default_origin("Green-E", 0) do
    "70202" # Government Center
  end
  defp default_origin(_, _) do
    ""
  end
end
