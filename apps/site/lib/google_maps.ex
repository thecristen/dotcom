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
    opts = default_options()
    |> Keyword.merge(opts)

    path
    |> URI.parse
    |> do_signed_url(opts[:client_id], opts[:signing_key], opts)
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

  @type t :: %{
    :results => [address],
    :status => String.t,
    :error_message => String.t
  }

  @type address :: %{
    :address_components => [address_component],
    :formatted_address => String.t, # "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA"
    :geometry => geometry,
    :types => [ String.t ],
    :place_id => String.t,
    :partial_match => boolean   # indicates that the geocoder did not return an exact match
  }                             # for the original request, though it was able to match part of the requested address.

  @type geometry :: %{
    :location => lat_lng,
    :location_type => String.t,
    :viewport => viewport,
    :bounds => viewport # Optionally returned
  }

  @type address_component :: %{
    :long_name => String.t | integer,
    :short_name => String.t | integer,
    :types => [ String.t ]
  }

  @type lat_lng :: %{ :lat => float, :lng => float  }

  @type viewport :: %{
    :northeast => lat_lng,
    :southwest => lat_lng
  }

  # possible status codes:
  #   OK
  #   ZERO_RESULTS
  #   OVER_QUERY_LIMIT
  #   REQUEST_DENIED
  #   INVALID_REQUEST
  #   UNKNOWN_ERROR
end
