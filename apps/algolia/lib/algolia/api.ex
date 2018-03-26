defmodule Algolia.Api do
  alias Algolia.Config
  require Logger

  @type t :: %{routes: success | error, stops: success | error}
  @type success :: :ok
  @type error :: {:error, HTTPoison.Response.t | HTTPoison.Error.t}

  @indexes Application.get_env(:algolia, :indexes, [])

  @doc """
  Updates stops and routes data on Algolia.
  """
  @spec update(String.t) :: t
  def update(host \\ "algolia.net") when is_binary(host) do
    Map.new(@indexes, &{&1, update_index(&1, host, Config.config())})
  end

  @spec update_index(atom, String.t, Config.t) :: success | error
  def update_index(index_module, base_url, %Config{} = config) do
    index_module.all()
    |> Enum.map(&build_data_object/1)
    |> build_request_object()
    |> send_update(base_url, index_module, config)
  end

  @spec send_update({:ok, Poison.Parser.t} | {:error, :invalid} | {:error, {:invalid, String.t}},
                    String.t, atom, Config.t) :: success | error
  defp send_update({:ok, request}, base_url, index_module, %Config{} = config) do
    base_url
    |> generate_url(index_module, config)
    |> HTTPoison.post(request, headers(config))
    |> parse_response()
  end
  defp send_update({:error, error}, _, _, %Config{}) do
    {:error, {:json_error, error}}
  end

  @spec generate_url(String.t, atom, Config.t) :: String.t
  defp generate_url(host, index_module, %Config{} = config) do
    Path.join([base_url(host, config), "1", "indexes", index_module.index_name(), "batch"])
  end

  defp base_url("algolia" <> _ = host, %Config{app_id: app_id}) do
    "https://" <> app_id <> "." <> host
  end
  defp base_url(host, %Config{}) when is_binary(host) do
    host
  end

  @spec parse_response({:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}) :: success | error
  defp parse_response({:ok, %HTTPoison.Response{status_code: 200}}), do: :ok
  defp parse_response({:ok, %HTTPoison.Response{} = response}), do: {:error, response}
  defp parse_response({:error, %HTTPoison.Error{} = error}), do: {:error, error}

  defp build_request_object(data) do
    Poison.encode(%{requests: data})
  end

  @spec build_data_object(Algolia.Object.t) :: map
  def build_data_object(data) do
    %{
      action: "addObject",
      body: do_build_data_object(data)
    }
  end

  @spec do_build_data_object(Algolia.Object.t) :: map
  defp do_build_data_object(data) do
    data
    |> Algolia.Object.data()
    |> set_rank(data)
    |> Map.merge(%{
      objectID: Algolia.Object.object_id(data),
      url: Algolia.Object.url(data)
    })
  end

  @spec headers(Config.t) :: [{String.t, String.t}]
  defp headers(%Config{app_id: app_id, admin: admin}) do
    [
      {"X-Algolia-API-Key", admin},
      {"X-Algolia-Application-Id", app_id}
    ]
  end

  @type rank :: 1 | 2 | 3 | 4

  @spec set_rank(map, Stops.Stop.t | Routes.Route.t | map) :: map
  defp set_rank(%{routes: []} = data, %Stops.Stop{}) do
    :ok = Logger.warn("stop has no routes: #{inspect(data)}")
    do_set_rank(4, data)
  end
  defp set_rank(%{routes: routes} = data, %Stops.Stop{}) do
    routes
    |> Enum.map(fn %Algolia.Stop.Route{type: type} -> rank_route_by_type(type) end)
    |> Enum.sort()
    |> List.first()
    |> do_set_rank(data)
  end
  defp set_rank(%{} = data, %Routes.Route{type: type}) do
    type
    |> rank_route_by_type()
    |> do_set_rank(data)
  end
  defp set_rank(data, _) do
    do_set_rank(1, data)
  end

  @spec do_set_rank(rank, map) :: map
  defp do_set_rank(rank, %{} = data) when rank in 1..4 do
    Map.put(data, :rank, rank)
  end

  @spec rank_route_by_type(Routes.Route.type_int) :: rank
  defp rank_route_by_type(0), do: 3
  defp rank_route_by_type(1), do: 3
  defp rank_route_by_type(2), do: 2
  defp rank_route_by_type(3), do: 4
  defp rank_route_by_type(4), do: 1
end
