defmodule GoogleMaps do
  @moduledoc """

  Helper functions for working with the Google Maps API.

  """

  @host "https://maps.googleapis.com"
  @host_uri URI.parse(@host)

  @doc """
  Given a path, returns a full URL with a signature.

  Options:
  * client_id: client to use for the request
  * key: if no client ID is specified, a key to use
  * signing_key: the private key used to sign the path.

  If no options are passed, they'll be looked up out of the GoogleMaps
  configuration in config.exs
  """
  def signed_url(path, opts \\ []) do
    opts = default_options
    |> Keyword.merge(opts)

    path
    |> URI.parse
    |> do_signed_url(opts[:client_id], opts[:signing_key], opts)
  end

  defp default_options do
    [
      client_id: get_env(:client_id),
      key: Application.get_env(:site, Site.ViewHelpers)[:google_api_key],
      signing_key: get_env(:signing_key)
    ]
  end

  defp get_env(key) do
    env = Application.get_env(:site, __MODULE__, [])
    case Keyword.get(env, key, "") do
      "${" <> _ ->
        # relx configuration that wasn't overriden; ignore
        ""
      value -> value
    end
  end

  defp do_signed_url(uri, "", _, opts) do
    uri
    |> append_api_key(opts[:key])
    |> prepend_host
  end
  defp do_signed_url(uri, _, "", opts) do
    uri
    |> append_api_key(opts[:key])
    |> prepend_host
  end
  defp do_signed_url(uri, client_id, signing_key, _) do
    uri
    |> append_query(:client, client_id)
    |> append_signature(signing_key)
    |> prepend_host
  end

  defp append_query(%URI{query: nil} = uri, key, value) do
    %{uri | query: "#{key}=#{value}"}
  end
  defp append_query(%URI{query: query} = uri, key, value) when is_binary(query) do
    %{uri | query: "#{query}&#{key}=#{value}"}
  end

  defp prepend_host(uri) do
    @host_uri
    |> URI.merge(uri)
    |> URI.to_string
  end

  defp append_api_key(uri, key) do
    # Fallback to the existing API key for now. -ps
    uri
    |> append_query(:key, key)
  end

  defp append_signature(uri, signing_key) do
    uri
    |> append_query(:signature, signature(uri, signing_key))
  end

  defp signature(uri, key) do
    de64ed_key = Base.url_decode64!(key)

    uri_string = uri |> URI.to_string

    binary_hash = :crypto.hmac(:sha, de64ed_key, uri_string)

    Base.url_encode64(binary_hash)
  end
end
