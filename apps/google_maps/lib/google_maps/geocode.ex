defmodule GoogleMaps.Geocode do
  @type t :: {:ok, [__MODULE__.Address.t]} | {:error, :zero_results | :internal_error}
  require Logger

  defmodule Address do
    @type t :: %__MODULE__{
      formatted: String.t,
      latitude: float,
      longitude: float
    }
    defstruct [
      formatted: "",
      latitude: 0.0,
      longitude: 0.0
    ]

    defimpl Stops.Position do
      def latitude(address), do: address.latitude
      def longitude(address), do: address.longitude
    end
  end

  alias __MODULE__.Address

  @spec geocode(String.t) :: t
  def geocode(address) when is_binary(address) do
    address
    |> geocode_url
    |> GoogleMaps.signed_url
    |> HTTPoison.get
    |> parse_google_response(address)
  end

  defp geocode_url(address) do
    "#{geocode_domain()}/maps/api/geocode/json?#{URI.encode_query([address: address])}"
  end

  defp geocode_domain do
    Application.get_env(:google_maps, :domain) || "https://maps.google.com"
  end

  defp parse_google_response({:error, error}, input_address) do
    internal_error(input_address, "HTTP error", "", error)
  end
  defp parse_google_response({:ok, %{status_code: 200, body: body}}, input_address) do
      case Poison.Parser.parse(body) do
        {:error, :invalid} ->
          internal_error(input_address, "Error parsing to JSON", "", body)
        {:error, {:invalid, parse_error_message}} ->
          internal_error(input_address, "Error parsing to JSON", "", body <> " " <> parse_error_message)
        {:ok, json} ->
          parse_json(json, input_address)
      end
  end
  defp parse_google_response({:ok, %{status_code: code, body: body}}, input_address) do
    internal_error(input_address, "Unexpected HTTP code", code, body)
  end

  defp parse_json(%{"status" => "OK", "results" => results}, input_address) do
    results(input_address, Enum.map(results, &parse_result/1))
  end
  defp parse_json(%{"status" => "ZERO_RESULTS"}, input_address) do
    zero_results(input_address)
  end
  defp parse_json(%{"status" => status} = parsed, input_address) do
    internal_error(input_address, "API error", status, Map.get(parsed, "error_message", ""))
  end

  defp parse_result(%{"geometry" => %{"location" => %{"lat" => lat, "lng" => lng}}, "formatted_address" => address}) do
    %Address{
      formatted: address,
      latitude: lat,
      longitude: lng
    }
  end

  defp results(input_address, results) do
    Logger.info fn -> "#{__MODULE__} address=#{inspect input_address} result=#{inspect results}" end
    {:ok, results}
  end

  defp zero_results(input_address) do
    Logger.info fn -> "#{__MODULE__} address=#{inspect input_address} result=ZERO_RESULTS" end
    {:error, :zero_results}
  end

  defp internal_error(input_address, error, code, body) do
    Logger.warn fn -> "#{__MODULE__} address=#{inspect input_address} error=#{inspect error} code=#{inspect code} body=#{inspect body}" end
    {:error, :internal_error}
  end
end
