defmodule SiteWeb.ScheduleController.Predictions do
  @moduledoc """

  Assigns predictions based on the currently selected route/stop/direction.

  """
  @behaviour Plug
  import Plug.Conn
  alias Predictions.Prediction

  @default_opts [
    predictions_fn: &Predictions.Repo.all/1,
  ]

  @typep predictions_fn :: (Keyword.t -> [Prediction.t] | {:error, any})

  @impl true
  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  @impl true
  def call(conn, opts) do
    if should_fetch_predictions?(conn) do
      conn
      |> async_assign(:predictions, fn -> predictions(conn, opts[:predictions_fn]) end)
      |> async_assign(:vehicle_predictions, fn -> vehicle_predictions(conn, opts[:predictions_fn]) end)
      |> await_assign(:predictions)
      |> await_assign(:vehicle_predictions)
    else
      conn
      |> assign(:predictions, [])
      |> assign(:vehicle_predictions, [])
    end
  end

  @spec should_fetch_predictions?(Plug.Conn.t) :: boolean
  @doc "We only fetch predictions if we selected an origin and the date is today."
  def should_fetch_predictions?(%{assigns: %{origin: nil}}) do
    false
  end
  def should_fetch_predictions?(%{assigns: assigns}) do
    Date.compare(assigns.date, Util.service_date(assigns.date_time)) == :eq
  end

  @spec predictions(Plug.Conn.t, predictions_fn) :: [Prediction.t]
  def predictions(%{assigns: %{
                       origin: origin,
                       destination: destination,
                       route: %{id: route_id},
                       direction_id: direction_id}}, predictions_fn)
  when not is_nil(origin) do
    [{:route, route_id} | prediction_query(origin, destination, direction_id)]
    |> predictions_fn.()
    |> case do
         {:error, _} ->
           []
         list ->
           list
           |> filter_stop_at_origin(origin.id)
           |> filter_missing_trip
       end
  end
  def predictions(_conn,  _) do
    []
  end

  defp prediction_query(origin, nil, direction_id) do
    [stop: origin.id, direction_id: direction_id]
  end
  defp prediction_query(origin, destination, _) do
    [stop: "#{origin.id},#{destination.id}"]
  end

  @spec filter_stop_at_origin([Prediction.t], Stops.Stop.id_t) :: [Prediction.t]
  defp filter_stop_at_origin(predictions, origin_id) do
    predictions
    |> Enum.reject(fn
      %Prediction{time: nil} -> false
      %Prediction{stop: %{id: ^origin_id}, departing?: false} -> true
      %Prediction{} -> false
    end)
  end

  @spec filter_missing_trip([Prediction.t]) :: [Prediction.t]
  defp filter_missing_trip(predictions) do
    Enum.filter(predictions, fn pred ->
      pred.trip != nil || pred.status != nil
    end)
  end

  @spec vehicle_predictions(Plug.Conn.t, predictions_fn) :: [Prediction.t]
  def vehicle_predictions(%{assigns: %{vehicle_locations: vehicle_locations}}, predictions_fn) do
    {trips, stops} = vehicle_locations
    |> Map.keys
    |> Enum.unzip

    stops = stops |> Enum.reject(&is_nil/1) |> Enum.uniq |> Enum.join(",")
    trips = trips |> Enum.reject(&is_nil/1) |> Enum.join(",")
    case predictions_fn.(trip: trips, stop: stops) do
      {:error, _} -> []
      list -> list
    end
  end
  def vehicle_predictions(_conn, _) do
    []
  end
end
