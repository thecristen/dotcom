defmodule Site.ScheduleV2Controller.Predictions do
  @moduledoc """

  Assigns predictions based on the currently selected route/stop/direction.

  """
  import Plug.Conn, only: [assign: 3]
  alias Predictions.Prediction

  @default_opts [
    predictions_fn: &Predictions.Repo.all/1,
  ]

  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  def call(conn, opts) do
    if conn.assigns.date == Util.service_date(conn.assigns.date_time) do
      conn
      |> assign_predictions(opts[:predictions_fn])
      |> gather_vehicle_predictions(opts[:predictions_fn])
    else
      conn
      |> assign(:predictions, [])
      |> assign(:vehicle_predictions, [])
    end
  end

  def assign_predictions(%{assigns: %{
                              origin: origin,
                              destination: destination,
                              route: %{id: route_id},
                              direction_id: direction_id}} = conn, predictions_fn)
  when not is_nil(origin) do
    predictions = [route: route_id]
    |> Keyword.merge(prediction_query(origin, destination, direction_id))
    |> predictions_fn.()
    |> filter_stop_at_origin(origin.id)

    assign(conn, :predictions, predictions)
  end
  def assign_predictions(conn,  _) do
    assign(conn, :predictions, [])
  end

  defp prediction_query(origin, nil, direction_id) do
    [stop: origin.id, direction_id: direction_id]
  end
  defp prediction_query(origin, destination, _) do
    [stop: "#{origin.id},#{destination.id}"]
  end

  defp filter_stop_at_origin(predictions, origin_id) do
    predictions
    |> Enum.reject(fn
      %Prediction{time: nil} -> false
      %Prediction{stop: %{id: ^origin_id}, departing?: false} -> true
      %Prediction{} -> false
    end)
  end

  @spec gather_vehicle_predictions(Plug.Conn.t, ((String.t, String.t) -> Predictions.Prediction.t)) :: Plug.Conn.t
  def gather_vehicle_predictions(%{assigns: %{vehicle_locations: vehicle_locations}} = conn, predictions_fn) do
    {trips, stops} = vehicle_locations
    |> Map.keys
    |> Enum.unzip

    stops = Enum.join(stops, ",")
    trips  = Enum.join(trips , ",")
    vehicle_predictions = predictions_fn.(trip: trips, stop: stops)

    conn
    |> assign(:vehicle_predictions, vehicle_predictions)
  end
  def gather_vehicle_predictions(conn, _) do
    conn
    |> assign(:vehicle_predictions, [])
  end
end
