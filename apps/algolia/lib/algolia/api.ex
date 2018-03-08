defmodule Algolia.Api do
  alias Algolia.Config

  @type t :: %{routes: success | error, stops: success | error}
  @type success :: :ok
  @type error :: {:error, HTTPoison.Response.t | HTTPoison.Error.t}

  @indexes Application.get_env(:algolia, :indexes, [])

  @doc """
  Updates stops and routes data on Algolia. Stops data does not include bus stops.
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
    app_id <> "." <> host
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
end
