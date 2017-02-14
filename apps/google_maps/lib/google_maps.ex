defmodule GoogleMaps do
  @moduledoc """

  Helper functions for working with the Google Maps API.

  """
  alias Stops.Position

  @host "https://maps.googleapis.com"
  @host_uri URI.parse(@host)
  @web "https://maps.google.com"
  @web_uri URI.parse(@web)

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
    opts = default_options()
    |> Keyword.merge(opts)

    path
    |> URI.parse
    |> do_signed_url(opts[:client_id], opts[:signing_key], opts)
  end

  @doc """
  Returns the url to view directions to a location on https://maps.google.com.
  """
  @spec direction_map_url(Position.t, Position.t) :: String.t
  def direction_map_url(origin, destination) do
    origin_lat = Position.latitude(origin)
    origin_lng = Position.longitude(origin)
    dest_lat = Position.latitude(destination)
    dest_lng = Position.longitude(destination)
    path = Path.join(["/", "maps", "dir", URI.encode("#{origin_lat},#{origin_lng}"), URI.encode("#{dest_lat},#{dest_lng}")])
    %{@web_uri | path: path}
    |> prepend_host(@web)
  end

  def default_options do
    [
      client_id: get_env(:client_id),
      key: get_env(:google_api_key),
      signing_key: get_env(:signing_key)
    ]
  end

  @doc "Given an width, and height returns a URL to a static map image."
  @spec static_map_url(pos_integer, pos_integer, Keyword.t) :: String.t
  def static_map_url(width, height, opts) do
    opts
    |> Keyword.put(:size, "#{width}x#{height}")
    |> URI.encode_query
    |> (fn query -> "/maps/api/staticmap?#{query}" end).()
    |> signed_url
  end


  defp get_env(key) do
    case Application.get_env(:google_maps, key) do
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

  defp prepend_host(uri, host \\ @host_uri) do
    host
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

  def scale(list_of_width_height_pairs) do
    list_of_width_height_pairs
    |> Enum.flat_map(fn {width, height} ->
      [
        {width, height, 1},
        {width, height, 2}
      ]
    end)
    |> Enum.sort_by(fn {width, _, scale} -> width * scale end)
  end
end
