defmodule Site.ScheduleV2Controller.Predictions do
  @moduledoc """

  Assigns predictions based on the currently selected route/stop/direction.

  """
  import Plug.Conn, only: [assign: 3]
  alias Stops.Stop

  def init([]), do: []

  def call(conn, opts) do
    conn
    |> assign_predictions(Util.service_date(), Keyword.get(opts, :predictions_fn, &Predictions.Repo.all/1))
    |> gather_vehicle_predictions(Keyword.get(opts, :predictions_fn, &Predictions.Repo.all/1))
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
                              origin: %Stop{id: stop_id},
                              route: %{id: route_id},
                              direction_id: direction_id}} = conn, _, predictions_fn)
  do
    stops = Enum.join([stop_id, get_destination_id(conn.assigns.destination)], ",")
    predictions = [direction_id: direction_id, stop: stops, route: route_id]
    |> predictions_fn.()

    assign(conn, :predictions, predictions)
  end
  def assign_predictions(conn, _, _) do
    assign(conn, :predictions, [])
  end

  defp get_destination_id(%Stop{id: stop_id}), do: stop_id
  defp get_destination_id(_), do: ""


  @spec gather_vehicle_predictions(Plug.Conn.t, ((String.t, String.t) -> Predictions.Prediction.t)) :: Plug.Conn.t
  def gather_vehicle_predictions(%{assigns: %{vehicle_locations: vehicle_locations}} = conn, predictions_fn) do
    {stops, trips} = vehicle_locations
    |> Enum.reduce({"", ""}, fn ({{trip, stop}, _vehicle}, {stops, trips}) ->
      {"#{stop}," <> stops,
       "#{trip}," <> trips}
    end)

    vehicle_predictions = predictions_fn.(trip: trips, stop: stops)

    conn
    |> assign(:vehicle_predictions, vehicle_predictions)
  end
  def gather_vehicle_predictions(conn, _) do
    conn
  end
end
