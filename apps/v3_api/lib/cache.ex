defmodule V3Api.Cache do
  @moduledoc """
  Cache HTTP responses from the V3 API.

  Static data such as schedules and stops do not change frequently. However,
  we do want to check in with the API periodically to make sure we have the
  most recent data. This module stores the previous HTTP responses, and can
  return them if the server says that the data is unchanged.
  """
  use GenServer
  alias HTTPoison.Response

  @type url :: String.t()
  @type params :: Enumerable.t()

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @doc """
  Given a URL, parameters, and an HTTP response:
  - If the HTTP response is a 304 Not Modified, return the previously cached response
  - If the HTTP response is a 200, 400, or 404, cache it and return the response
  - If the HTTP response is anything else, try to return a cached response, otherwise return the response as-is
  """
  @spec cache_response(url, params, Response.t) :: {:ok, Response.t} | {:error, :no_cached_response}
  def cache_response(name \\ __MODULE__, url, params, response)

  def cache_response(name, url, params, %{status_code: 304}) do
    {:ok, :ets.lookup_element(name, {url, params}, 3)}
  rescue
    ArgumentError ->
      {:error, :no_cached_response}
  end

  def cache_response(name, url, params, %{status_code: status_code} = response)
  when status_code in [200, 400, 404] do
    key = {url, params}
    last_modified = header(response, "last-modified")
    true = :ets.insert(name, {key, last_modified, response})
    {:ok, response}
  end

  def cache_response(name, url, params, response) do
    {:ok, :ets.lookup_element(name, {url, params}, 3)}
  rescue
    ArgumentError ->
      {:ok, response}
  end

  @doc """
  Return a list of cache headers for the given URL/parameters.
  """
  @spec cache_headers(url, params) :: [{String.t, String.t}]
  def cache_headers(name \\ __MODULE__, url, params) do
    last_modfied = :ets.lookup_element(name, {url, params}, 2)
    [{"if-modified-since", last_modfied}]
  rescue
    ArgumentError ->
      []
  end

  defp header(%{headers: headers}, header) do
    case Enum.find(headers, &String.downcase(elem(&1, 0)) == header) do
      {_, value} -> value
      nil -> nil
    end
  end

  @impl GenServer
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    ^name = :ets.new(name, [:set, :named_table, :public, {:read_concurrency, true}, {:write_concurrency, true}])
    {:ok, []}
  end
end
