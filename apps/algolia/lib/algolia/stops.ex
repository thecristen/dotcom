defmodule Algolia.Stops do
  @behaviour Algolia.Index
  @repo :algolia
        |> Application.get_env(:repos)
        |> Keyword.fetch!(:stops)

  @impl Algolia.Index
  def all do
    [0, 1, 2, 3, 4]
    |> Task.async_stream(& @repo.by_route_type({&1, []}))
    |> Stream.flat_map(fn {:ok, stops} -> stops end)
    |> Enum.into([])
  end

  @impl Algolia.Index
  def index_name, do: "stops"
end
