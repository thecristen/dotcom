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
    predictions = [route: route_id, direction_id: direction_id, stop: stop_id]
    |> Predictions.Repo.all

    assign(conn, :predictions, predictions)
  end
end
