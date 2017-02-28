defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  alias Alerts.Parser

  @spec all() :: [Alerts.Alert.t]
  def all do
    cache nil, fn _ ->
      v3_api_all().data
      |> Enum.map(&Parser.Alert.parse/1)
    end
  end

  @spec by_id(String.t) :: Alerts.Alert.t | nil
  def by_id(id) do
    all()
    |> Enum.find(&(&1.id == id))
  end

  @spec banner() :: Alerts.Banner.t | nil
  def banner() do
    cache &v3_api_all/0, &do_banner/1
  end

  defp v3_api_all do
    cache nil, fn _ ->
      V3Api.Alerts.all()
    end
  end

  @spec do_banner((() -> JsonApi.t)) :: {:ok, Alerts.Banner.t | nil}
  def do_banner(alert_fn) do
    alert_fn.().data
    |> Enum.flat_map(&Parser.Banner.parse/1)
    |> List.first
  end
end
