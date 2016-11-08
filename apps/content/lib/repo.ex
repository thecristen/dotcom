defmodule Content.Repo do
  @doc """

  Fetches a %Content.Page{} for a given path.

  """
  @spec page(String.t) :: {:ok, Content.Page.t} | {:error, any}
  def page(path) when is_binary(path) do
    params = [{:_format, "json"}]

    with {:ok, full_url} <- build_url(path),
         {:ok, response} <- HTTPoison.get(full_url, [], params: params),
         %{status_code: 200, body: body} <- response do
      Content.Parse.Page.parse(body)
    else
      tuple = {:error, _} -> tuple
      error -> {:error, "while fetching page #{path}: #{inspect error}"}
    end
  end

  defp build_url(path = "/" <> _) do
    base_url = case Application.get_env(:content, :drupal_root) do
                 {:system, envvar} -> System.get_env(envvar)
                 value -> value
               end
    merge_urls(base_url, path)
  end
  defp build_url(path) when is_binary(path) do
    build_url("/" <> path)
  end

  defp merge_urls(nil, _) do
    {:error, "undefined DRUPAL_ROOT"}
  end
  defp merge_urls(base_url, path) do
    {:ok, base_url
    |> URI.merge(path)
    |> URI.to_string}
  end
end
