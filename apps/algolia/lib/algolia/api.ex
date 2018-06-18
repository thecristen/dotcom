defmodule Algolia.Api do
  alias Algolia.Config
  defstruct [:host, :index, :action, :body]

  @type t :: %__MODULE__{
    host: String.t | nil,
    index: String.t | nil,
    action: String.t | nil,
    body: String.t | nil
  }

  @spec post(t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def post(%__MODULE__{index: index, action: action, body: body} = opts)
  when is_binary(index) and is_binary(action) and is_binary(body) do
    config = Config.config()

    body = rewrite_indexes(body, opts, Application.get_env(:algolia, :index_suffix))

    opts
    |> generate_url(config)
    |> HTTPoison.post(body, headers(config), hackney: hackney_opts(opts))
  end

  defp rewrite_indexes(body, %__MODULE__{}, "") do
    body
  end
  defp rewrite_indexes(body, %__MODULE__{action: "queries"}, <<suffix::binary>>) do
    {:ok, %{"requests" => requests}} = Poison.decode(body)
    Poison.encode!(%{"requests" => Enum.map(requests, &rewrite_index(&1, suffix))})
  end
  defp rewrite_indexes(body, %__MODULE__{}, <<_::binary>>) do
    body
  end

  defp rewrite_index(%{"indexName" => index_name} = request, suffix) do
    Map.put(request, "indexName", index_name <> suffix)
  end

  @spec generate_url(t, Config.t) :: String.t
  defp generate_url(%__MODULE__{} = opts, %Config{} = config) do
    Path.join([base_url(opts, config), "1", "indexes", opts.index, opts.action])
  end

  defp base_url(%__MODULE__{host: nil}, %Config{app_id: app_id}) do
    "https://" <> app_id <> "-dsn.algolia.net"
  end
  defp base_url(%__MODULE__{host: "http://localhost:" <> _ = host}, %Config{}) do
    host
  end

  @spec headers(Config.t) :: [{String.t, String.t}]
  defp headers(%Config{app_id: <<app_id::binary>>, admin: <<admin::binary>>}) do
    [
      {"X-Algolia-API-Key", admin},
      {"X-Algolia-Application-Id", app_id}
    ]
  end

  defp hackney_opts(%__MODULE__{index: "*"}) do
    # By default, hackney encodes "*"; passing this option skips this encoding
    # see https://github.com/benoitc/hackney/issues/272#issuecomment-174334135
    [path_encode_fun: fn path -> path end]
  end
  defp hackney_opts(%__MODULE__{}) do
    []
  end
end
