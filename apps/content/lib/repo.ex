defmodule Content.Repo do
  @doc """

  Fetches a %Content.Page{} for a given path.

  """
  @spec page(String.t) :: {:ok, Content.Page.t} | {:error, any}
  def page(path) when is_binary(path) do
    params = [{:_format, "json"}]

    with {:ok, full_url} <- build_url(path),
         {:ok, response} <- HTTPoison.get(full_url, [], params: params),
         %{status_code: 200, body: body} <- response,
         {:ok, page} <- Content.Parse.Page.parse(body) do
      {:ok, Content.Page.rewrite_static_files(page)}
    else
      tuple = {:error, _} -> tuple
      error -> {:error, "while fetching page #{path}: #{inspect error}"}
    end
  end

  defp build_url(path) do
    case Content.Config.url(path) do
      nil -> {:error, "undefined Drupal root"}
      url -> {:ok, url}
    end
  end
end
