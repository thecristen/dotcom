defmodule GoogleMaps.Geocode do
  @type t :: {:ok, [__MODULE__.Address.t]} | {:error, error_status, any}
  @type error_status :: :zero_results | :over_query_limit | :request_denied | :invalid_request | :unknown_error

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
    |> call_google_api
    |> parse_google_response
  end

  defp call_google_api(address) do
    HTTPoison.get(
      geocode_url,
      [],
      params: [address: address, key: GoogleMaps.default_options[:google_api_key]])
  end

  defp geocode_url do
    "#{geocode_domain}/maps/api/geocode/json"
  end

  defp geocode_domain do
    Application.get_env(:site, GoogleMaps)[:domain] || "https://maps.google.com"
  end

  defp parse_google_response({:error, error}) do
    {:error, :unknown_error, error}
  end
  defp parse_google_response({:ok, response}) do
    response
    |> parse_http_response
  end

  defp parse_http_response(%{status_code: code, body: body}) when code != 200 do
    {:error, :unknown_error, body}
  end
  defp parse_http_response(%{body: body}) do
    body
    |> Poison.Parser.parse
    |> parse_result_json
  end

  defp parse_result_json({:error, error}) do
    {:error, :unknown_error, error}
  end
  defp parse_result_json({:ok, %{"status" => status} = parsed}) when status != "OK" do
    {:error,
     status |> String.downcase |> String.to_existing_atom,
     Map.get(parsed, "error_message", "")}
  end
  defp parse_result_json({:ok, %{"results" => results}}) do
    {:ok, Enum.map(results, &parse_result/1)}
  end

  defp parse_result(%{"geometry" => %{"location" => %{"lat" => lat, "lng" => lng}}, "formatted_address" => address}) do
    %Address{
      formatted: address,
      latitude: lat,
      longitude: lng
    }
  end
end
