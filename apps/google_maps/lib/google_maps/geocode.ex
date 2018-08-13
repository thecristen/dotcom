defmodule GoogleMaps.Geocode do
  use RepoCache, ttl: :timer.hours(24)

  alias GoogleMaps.Geocode.Address
  require Logger

  @type t :: {:ok, nonempty_list(Address.t)} | {:error, :zero_results | :internal_error}

  @bounds %{
    east: 41.3193,
    north: -71.9380,
    west: 42.8266,
    south: -69.6189
  }

  @spec geocode(String.t) :: t
  def geocode(address) when is_binary(address) do
    cache address, fn address ->
      address
      |> geocode_url
      |> GoogleMaps.signed_url()
      |> HTTPoison.get()
      |> parse_google_response(address)
    end
  end

  defp geocode_url(address) do
    URI.to_string(%URI{
      path: "/maps/api/geocode/json",
      query: URI.encode_query([
        address: address,
        bounds: "#{@bounds.east},#{@bounds.north}|#{@bounds.west},#{@bounds.south}"
      ])
    })
  end

  defp parse_google_response({:error, error}, input_address) do
    internal_error(input_address, "HTTP error", fn -> "error=#{inspect error}" end)
  end
  defp parse_google_response({:ok, %{status_code: 200, body: body}}, input_address) do
    case Poison.Parser.parse(body) do
      {:error, :invalid} ->
        internal_error(input_address, "Error parsing to JSON",
                        fn -> "body=#{inspect body}" end)
      {:error, {:invalid, parse_error_message}} ->
        internal_error(input_address, "Error parsing to JSON",
                        fn -> "body=#{inspect body} error_message=#{inspect parse_error_message}" end)
      {:ok, json} ->
        parse_json(json, input_address)
    end
  end
  defp parse_google_response({:ok, %{status_code: code, body: body}}, input_address) do
    internal_error(input_address, "Unexpected HTTP code", fn -> "code=#{inspect code} body=#{inspect body}" end)
  end

  @spec parse_json(map, String.t) :: t
  defp parse_json(%{"status" => "OK", "results" => results}, input_address) do
    results(input_address, Enum.map(results, &parse_result/1))
  end
  defp parse_json(%{"status" => "ZERO_RESULTS"}, input_address) do
    zero_results(input_address)
  end
  defp parse_json(%{"status" => status} = parsed, input_address) do
    internal_error(input_address, "API error",
                   fn -> "status=#{inspect status} error_message=#{inspect(Map.get(parsed, "error_message", ""))}" end)
  end

  @spec parse_result(map) :: Address.t
  defp parse_result(%{"geometry" => %{"location" => %{"lat" => lat, "lng" => lng}}, "formatted_address" => address}) do
    %Address{
      formatted: address,
      latitude: lat,
      longitude: lng
    }
  end

  @spec results(String.t, [Address.t]) :: t
  defp results(input_address, []) do
    zero_results(input_address)
  end
  defp results(input_address, results) do
    _ = Logger.info fn -> "#{__MODULE__} address=#{inspect input_address} result=#{inspect results}" end
    {:ok, results}
  end

  @spec zero_results(String.t) :: t
  defp zero_results(input_address) do
    _ = Logger.info fn -> "#{__MODULE__} address=#{inspect input_address} result=ZERO_RESULTS" end
    {:error, :zero_results}
  end

  @spec internal_error(String.t, String.t, (() -> String.t)) :: t
  defp internal_error(input_address, message, error_fn) do
    _ = Logger.warn fn -> "#{__MODULE__} address=#{inspect input_address} message=#{inspect message} #{error_fn.()}" end
    {:error, :internal_error}
  end
end
