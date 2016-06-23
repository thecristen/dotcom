defmodule Site.ScheduleController.Query do
  @doc """
  Given a conn, returns the relevant parameters for making a query
  of Schedules.Repo.all/1
  """
  def schedule_query(%Plug.Conn{params: params, assigns: assigns}) do
    schedule_params = [
      route: params["route"],
      date: assigns[:date],
      direction_id: assigns[:direction_id]]

    stop_id = case Map.get(params, "origin", "") do
                "" ->
                  assigns[:all_stops]
                  |> (fn [stop|_] -> stop.id end).()
                value -> value
              end

    schedule_params
    |> Keyword.put(:stop, stop_id)
  end
end
