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

    method
    |> time_request(request_path, body, request_headers, opts)
    |> handle_response()
  end

  @spec handle_response({:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t})
  :: Content.CMS.response
  defp handle_response(response) do
    case response do
      {:ok, %{status_code: code, body: body}} when code in [200, 201] ->
        decode_body(body)
      {:ok, %HTTPoison.Response{status_code: code, headers: headers}} when code in [301, 302] ->
        get_redirect(headers)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      _ ->
        {:error, :invalid_response}
    end
  end

  @spec decode_body(String.t) :: {:ok, [map()] | map()} | {:error, :invalid_response}
  defp decode_body(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      _ -> {:error, :invalid_response}
    end
  end

  @spec get_redirect([{String.t, String.t}]) :: {:error, :invalid_response | {:redirect, String.t}}
  defp get_redirect(header_list) do
    header_list
    |> Enum.find(fn {key, _} -> String.downcase(key) == "location" end)
    |> do_get_redirect()
  end

  defp do_get_redirect(nil), do: {:error, :invalid_response}
  defp do_get_redirect({_key, url}) do
    %URI{path: path, query: query} = URI.parse(url)
    {:error, {:redirect, parse_redirect_query(path, query)}}
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
