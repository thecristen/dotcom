defmodule Algolia.Api do
  @type t :: %{routes: success | error, stops: success | error}
  @type success :: :ok
  @type error :: {:error, HTTPoison.Response.t | HTTPoison.Error.t}

  @keys Application.get_env(:algolia, :keys)
  @application_id Keyword.fetch!(@keys, :app_id)
  if @application_id == nil, do: raise Algolia.MissingAppIdError

  @admin_key Keyword.fetch!(@keys, :admin)
  if @admin_key == nil, do: raise Algolia.MissingAdminKeyError

  if Keyword.fetch!(@keys, :search) == nil do
    # used by javascript in Site app
    raise Algolia.MissingSearchKeyError
  end

  @base_url "https://" <> @application_id <> ".algolia.net/1/indexes/"

  @headers [
    {"X-Algolia-API-Key", @admin_key},
    {"X-Algolia-Application-Id", @application_id}
  ]

  @indexes Application.get_env(:algolia, :indexes, [])

  @doc """
  Updates stops and routes data on Algolia. Stops data does not include bus stops.
  """
  @spec update(String.t) :: t
  def update(base_url \\ @base_url) do
    Map.new(@indexes, &{&1, update_index(&1, base_url)})
  end

  @spec generate_url(String.t, atom) :: String.t
  defp generate_url(base_url, index_module) do
    Path.join([base_url, index_module.index_name(), "batch"])
  end

  @spec update_index(atom, String.t) :: success | error
  def update_index(index_module, base_url) do
    index_module.all()
    |> Enum.map(&build_data_object/1)
    |> build_request_object()
    |> send_update(base_url, index_module)
  end

  @spec send_update({:ok, Poison.Parser.t} | {:error, :invalid} | {:error, {:invalid, String.t}},
                    String.t, atom) :: success | error
  defp send_update({:ok, request}, base_url, index_module) do
    base_url
    |> generate_url(index_module)
    |> HTTPoison.post(request, @headers)
    |> parse_response()
  end
  defp send_update({:error, error}, _, _) do
    {:error, {:json_error, error}}
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
end
