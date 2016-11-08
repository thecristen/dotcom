defmodule Content.Repo do
  @spec page([...]) :: {:ok, Content.Page.t} | {:error, any}
  def page(opts) when is_list(opts) do
    url = Keyword.fetch!(opts, :url)
    opts = opts
    |> Keyword.drop([:url])
    |> Keyword.put(:_format, "json")

    with {:ok, response} <- HTTPoison.get(full_url(url), [], params: opts),
         %{status_code: 200, body: body} <- response do
      Content.Parse.Page.parse(body)
    else
      tuple = {:error, _} -> tuple
      error -> {:error, "while fetching page #{url}:#{inspect opts}: #{inspect error}"}
    end
  end

  defp full_url(url = "/" <> _) do
    base_url = case Application.get_env(:content, :drupal_root) do
                 {:system, envvar} -> System.get_env(envvar)
                 value when is_binary(value) -> value
               end
    base_url
    |> URI.merge(url)
    |> URI.to_string
  end
  defp full_url(url) when is_binary(url) do
    full_url("/" <> url)
  end
end
