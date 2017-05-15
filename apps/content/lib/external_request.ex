defmodule Content.ExternalRequest do
  import Content.CMS.TimeRequest, only: [time_request: 5]
  @moduledoc """
    Exposes the function that is used by all requests to simplify testing. This
    function is not intended for direct use. Please see Content.HTTPClient to
    issue a request.
  """

  @spec process(atom, String.t, String.t, Keyword.t) :: {:ok, Poison.Parser.t} | {:error, map} | {:error, String.t}
  def process(method, path, body \\ "", params \\ []) do
    request_path = full_url(path)
    request_headers = build_headers(method)

    method
    |> time_request(request_path, body, request_headers, params)
    |> handle_response()
  end

  defp handle_response(response) do
    case response do
      {:ok, %{status_code: code, body: body}} when code in [200, 201] ->
        parse_body(body)
      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:error, %{status_code: code, reason: body}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{reason: reason}}
    end
  end

  defp parse_body(body) do
    case Poison.Parser.parse(body) do
      {:ok, parsed_body} -> {:ok, parsed_body}
      _error -> {:error, "Could not parse JSON response"}
    end
  end

  defp full_url(path) do
    Content.Config.url(path)
  end

  defp build_headers(:get), do: headers()
  defp build_headers(_), do: auth_headers()

  defp headers do
    ["Content-Type": "application/json"]
  end

  defp auth_headers do
    Keyword.merge(headers(), ["Authorization": "Basic #{encoded_auth_credentials()}"])
  end

  defp encoded_auth_credentials, do: Base.encode64("#{username()}:#{password()}")

  defp username, do: System.get_env("DRUPAL_USERNAME")

  defp password, do: System.get_env("DRUPAL_PASSWORD")
end
