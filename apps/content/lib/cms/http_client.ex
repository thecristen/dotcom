defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.CMS.TimeRequest, only: [time_request: 2]

  def view(path, params \\ []) do
    params = Keyword.merge(params, [_format: "json"])
    with {:ok, url} <- make_url(path),
      {:ok, %{status_code: 200, body: body}} <- time_request(url, params),
      {:ok, parsed} <- Poison.Parser.parse(body) do
      {:ok, parsed}
    else
      {:error, :no_root} -> {:error, "No content root configured"}
      {:ok, %HTTPoison.Response{status_code: status}} -> {:error, "HTTP status was #{status}"}
      {:error, %HTTPoison.Error{}} -> {:error, "Unknown error with HTTP request"}
      {:error, {:invalid, _}} -> {:error, "Could not parse JSON response"}
      _ -> {:error, "Unknown error occurred"}
    end
  end

  defp make_url(path) do
    if url = Content.Config.url(path) do
      {:ok, url}
    else
      {:error, :no_root}
    end
  end
end
