defmodule News.Repo do

  config_dir = Application.fetch_env!(:news, :post_dir)
  post_dir = case config_dir do
               <<"/", _::binary>> -> config_dir
               _ -> Application.app_dir(:news, config_dir)
             end
  @post_filenames post_dir
  |> File.ls!
  |> Enum.map(&(Path.join(post_dir, &1)))
  |> Enum.map(&Path.expand/1)

  def all(opts \\ []) do
    case Keyword.get(opts, :limit, :infinity) do
      :infinity ->
        do_all(@post_filenames)
      limit when is_integer(limit) ->
        @post_filenames
        |> Enum.sort
        |> Enum.reverse
        |> Enum.take(limit)
        |> do_all
    end
  end

  def get!(_, id) do
    @post_filenames
    |> Enum.filter(&(&1 |> String.contains?(id)))
    |> do_all
    |> Enum.filter(&(&1.id == id))
    |> List.first
  end

  defp do_all(filenames) do
    filenames
    |> Enum.map(&News.Jekyll.parse_file/1)
    |> Enum.filter_map(
    fn
      {:ok, _} -> true
      {:error, _} -> false
    end,
    fn {:ok, parsed} -> parsed end)
  end
end
