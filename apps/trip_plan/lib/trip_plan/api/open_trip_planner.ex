defmodule TripPlan.Api.OpenTripPlanner do
  @behaviour TripPlan.Api
  require Logger
  import __MODULE__.Builder, only: [build_params: 1]
  import __MODULE__.Parser, only: [parse_json: 1, parse_nearby: 1]
  alias TripPlan.NamedPosition
  alias Stops.Position

  def plan(from, to, opts) do
    with {:ok, params} <- build_params(opts),
         params = Map.merge(params,
         %{
           "fromPlace" => location(from),
           "toPlace" => location(to),
           "mode" => "WALK,TRANSIT",
           "showIntermediateStops" => "true",
           "format" => "json",
           "locale" => "en"
         }),
           root_url = config(:root_url),
         full_url = "#{root_url}/otp/routers/default/plan"
    do
      send_request(full_url, params, &parse_json/1)
    end
  end

  def stops_nearby(location) do
    root_url = config(:root_url)
    full_url = "#{root_url}/otp/routers/default/index/stops"
    params = %{
      lat: Position.latitude(location),
      lon: Position.longitude(location),
      radius: 1000
    }
    send_request(full_url, params, &parse_nearby/1)
  end

  def config(key) do
    case Application.fetch_env!(:trip_plan, OpenTripPlanner)[key] do
      {:system, var, default} ->
        System.get_env(var) || default
      value ->
        value
    end
  end

  defp send_request(url, params, parser) do
    with {:ok, response} <- log_response(url, params),
         %{status_code: 200, body: body} <- response do
      parser.(body)
    else
      %{status_code: _} = response ->
        {:error, response}
      error ->
        error
    end
  end

  defp log_response(url, params) do
    {duration, response} = :timer.tc(HTTPoison, :get, [url, [], [params: params, recv_timeout: 10_000]])
    _ = Logger.info(fn ->
      "#{__MODULE__}.plan_response url=#{url} params=#{inspect params} #{status_text(response)} duration=#{duration / :timer.seconds(1)}"
    end)
    response
  end

  defp status_text({:ok, %{status_code: code, body: body}}) do
    "status=#{code} content_length=#{byte_size(body)}"
  end
  defp status_text({:error, error}) do
    "status=error error=#{inspect error}"
  end

  defp location(%NamedPosition{} = np) do
    "#{np.name}::#{Position.latitude(np)},#{Position.longitude(np)}"
  end
  defp location(position) do
    "#{Position.latitude(position)},#{Position.longitude(position)}"
  end
end
