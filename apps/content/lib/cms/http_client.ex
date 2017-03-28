defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  def view(path, params \\ []) do
    params = Keyword.merge(params, [_format: "json"])
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(make_url(path), [], params: params),
      {:ok, parsed} <- Poison.Parser.parse(body) do
      {:ok, parsed}
    else
      {:ok, %HTTPoison.Response{status_code: status}} -> {:error, "HTTP status was #{status}"}
      {:error, %HTTPoison.Error{}} -> {:error, "Unknown error with HTTP request"}
      {:error, {:invalid, _}} -> {:error, "Could not parse JSON response"}
      _ -> {:error, "Unknown error occurred"}
    end
  end

  defp make_url(path), do: Content.Config.root() <> path
end
