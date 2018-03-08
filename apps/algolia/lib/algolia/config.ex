defmodule Algolia.Config do
  require Logger

  defmodule Places do
    defstruct [:app_id, :search]

    @type t :: %__MODULE__{
      app_id: String.t | nil,
      search: String.t | nil
    }

    @spec config :: t
    def config do
      :algolia
      |> Application.get_env(:places_config)
      |> Enum.reduce(%__MODULE__{}, &Algolia.Config.do_config/2)
    end
  end

  defstruct [:app_id, :admin, :search, :places]

  @type t :: %__MODULE__{
    app_id: String.t | nil,
    admin: String.t | nil,
    search: String.t | nil,
    places: Algolia.Config.Places.t
  }

  @spec config :: t
  def config do
    :algolia
    |> Application.get_env(:config)
    |> Enum.reduce(%__MODULE__{}, &do_config/2)
    |> Map.put(:places, Places.config())
  end

  @spec do_config({atom, {:system, String.t} | String.t | nil}, __MODULE__ | Places.t) :: t
  def do_config({key, "$" <> _ = val}, %{__struct__: struct} = config) when struct in [__MODULE__, Places] do
    :ok = Logger.warn("unparsed #{inspect(struct)} environment variable: #{inspect(key)} #{inspect(val)}")
    config
  end
  def do_config({key, nil}, %{__struct__: struct} = config) when struct in [__MODULE__, Places] do
    :ok = Logger.warn("missing #{struct} environment variable: #{inspect(key)}")
    config
  end
  def do_config({key, {:system, system_key}}, config) do
    do_config({key, System.get_env(system_key)}, config)
  end
  def do_config({key, <<val::binary>>}, config) do
    Map.put(config, key, val)
  end
end
