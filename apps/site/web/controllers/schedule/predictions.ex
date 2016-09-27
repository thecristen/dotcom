defmodule Site.ScheduleController.Predictions do
  @moduledoc """

  Assigns predictions based on the currently selected route/stop/direction.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    if Laboratory.enabled?(conn, :predictions) do
      assign_predictions(conn)
    else
      assign(conn, :predictions, [])
    end
  end

  @doc """

  If we have an origin selected, then use that for the predictions.
  Otherwise, we use @from, assigned out of the schedules

  """
  def assign_predictions(%{assigns: %{
                              origin: stop_id,
                              route: %{id: route_id},
                              direction_id: direction_id}} = conn)
  when not is_nil(stop_id) do
    assign_route_stop_direction(conn, route_id, stop_id, direction_id)
  end
  def assign_predictions(%{assigns: %{
                              from: %{id: stop_id},
                              route: %{id: route_id},
                              direction_id: direction_id}} = conn) do
    assign_route_stop_direction(conn, route_id, stop_id, direction_id)
  end

  def assign_route_stop_direction(conn, route_id, stop_id, direction_id) do
    # Since we have both trips displayed which don't start at stop_id, as
    # well as trips which aren't on the given route, we check both and
    # combine the predictions.
    stop_predictions = [direction_id: direction_id, stop: stop_id]
    |> Predictions.Repo.all
    route_predictions = [route: route_id, direction_id: direction_id]
    |> Predictions.Repo.all

    all_predictions = [stop_predictions, route_predictions]
    |> Enum.concat
    |> Enum.uniq

    assign(conn, :predictions, all_predictions)
  end
end
