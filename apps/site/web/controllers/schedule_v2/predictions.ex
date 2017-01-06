defmodule Site.ScheduleV2Controller.Predictions do
  @moduledoc """

  Assigns predictions based on the currently selected route/stop/direction.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, opts) do
    assign_predictions(conn, Util.service_date(), Keyword.get(opts, :predictions_fn, &Predictions.Repo.all/1))
  end

  @doc """

  If we have an origin selected, then use that for the predictions.
  Otherwise, we use @from, assigned out of the schedules

  """
  def assign_predictions(%{assigns: %{date: date}} = conn, service_date, _)
  when date != service_date do
    assign(conn, :predictions, [])
  end
  def assign_predictions(%{assigns: %{
                              origin: stop_id,
                              route: %{id: route_id},
                              direction_id: direction_id}} = conn, _, predictions_fn)
  when not is_nil(stop_id) do
    predictions = [direction_id: direction_id, stop: stop_id, route: route_id]
    |> predictions_fn.()

    assign(conn, :predictions, predictions)
  end
  def assign_predictions(conn, _, _) do
    assign(conn, :predictions, [])
  end
end
