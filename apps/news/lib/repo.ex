defmodule News.Repo do
  @callback all_ids() :: [String.t]
  @callback get(String.t) :: {:ok, String.t} | {:error, any}

  use RepoCache, ttl: :timer.hours(3)
  require Logger

  @spec all(Keyword.t) :: [News.Post.t]
  def all(opts \\ []) do
    cache opts, fn opts ->
      case Keyword.get(opts, :limit, :infinity) do
        :infinity ->
          do_all(repo.all_ids)
        limit when is_integer(limit) ->
          repo.all_ids
          |> Enum.sort
          |> Enum.reverse
          |> Enum.take(limit)
          |> do_all
      end
    end
  end

  defp do_all(filenames) do
    filenames
    |> Enum.map(&parse_contents/1)
    |> Enum.filter_map(
    fn
      {:ok, _} -> true
      {:error, err} ->
        _ = Logger.debug("error in news entry: #{inspect err}")
        false
    end,
    fn {:ok, parsed} -> parsed end)
  end

  defp repo do
    Application.get_env(:news, :repo)
  end

  defp parse_contents(filename) do
    with {:ok, contents} <- repo.get(filename),
         {:ok, post} <- News.Jekyll.parse(contents),
           post <- put_in(post.id, parse_id(filename)) do
      {:ok, post}
    end
  end

  defp parse_id(filename) do
    filename
    |> Path.rootname
    |> String.split("-", parts: 4)
    |> List.last
  end
end
