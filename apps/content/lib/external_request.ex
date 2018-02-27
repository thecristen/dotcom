defmodule Content.ExternalRequest do
  import Content.CMS.TimeRequest, only: [time_request: 5]
  @moduledoc """
    Exposes the function that is used by all requests to simplify testing. This
    function is not intended for direct use. Please see Content.HTTPClient to
    issue a request.
  """

  @spec process(atom, String.t, String.t, Keyword.t) :: Content.CMS.response
  def process(method, path, body \\ "", opts \\ []) do
    request_path = full_url(path)
    request_headers = build_headers(method)

    response = time_request(method, request_path, body, request_headers, opts)
    handle_response(response, parse_headers(response))
  end

  @spec handle_response({:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}, map()) :: Content.CMS.response
  defp handle_response({:ok, %HTTPoison.Response{} = response}, %{"content-type" => "application/json"}) do
    case response do
      %{status_code: code, body: body} when code in [200, 201] ->
        decode_body(body)
      %{status_code: code} when code in [301, 302] ->
        get_redirect(response)
      %{status_code: code} when code in [400, 401, 403, 404, 406] ->
        {:error, :not_found} # drive handled errors to the 404 page
      _ ->
        {:error, :invalid_response} # unusual/unhandled status codes (will throw 500)
    end
  end
  defp handle_response({:ok, %HTTPoison.Response{}}, _header_map) do
    {:error, :not_found} # a response that isn't returned in JSON format
  end
  defp handle_response({:error, %HTTPoison.Error{}}, _header_map) do
    {:error, :invalid_response}
  end

  @spec decode_body(String.t) :: {:ok, [map()] | map()} | {:error, :not_found}
  defp decode_body(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      _ -> {:error, :invalid_response} # a malformed JSON response
    end
  end

  @spec get_redirect(HTTPoison.Response.t) :: {:error, :invalid_response | {:redirect, integer, String.t}}
  defp get_redirect(%HTTPoison.Response{headers: headers, status_code: status}) do
    headers
    |> Enum.find(fn {key, _} -> String.downcase(key) == "location" end)
    |> do_get_redirect(status)
  end

  @spec do_get_redirect({String.t, String.t} | nil, integer) :: {:error, {:redirect, integer, String.t} |
                                                                         :invalid_response}
  defp do_get_redirect(nil, _), do: {:error, :invalid_response}
  defp do_get_redirect({_key, url}, status_code) do
    %URI{path: path, query: query} = URI.parse(url)
    {:error, {:redirect, status_code, parse_redirect_query(path, query)}}
  end

  @spec parse_redirect_query(String.t, nil | String.t) :: String.t
  defp parse_redirect_query(path, query) when query in [nil, "_format=json"] do
    path
  end
  defp parse_redirect_query(path, query) do
    # If the redirect path happens to include query params,
    # Drupal will append the request query parameters to the redirect params.
    path <> "?" <> String.replace(query, "_format=json", "")
  end

  defp full_url(path) do
    Content.Config.url(path)
  end

  @spec parse_headers({:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}) :: map()
  defp parse_headers({:ok, %HTTPoison.Response{headers: header_list}}) do
    Map.new(header_list, fn {key, value} -> {String.downcase(key), value} end)
  end
  defp parse_headers({:error, %HTTPoison.Error{}}) do
    %{}
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
