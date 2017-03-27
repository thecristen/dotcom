defmodule Content.ApiHttp do
  @behaviour Content.Api

  def view(path, params \\ []) do
    params = Keyword.merge(params, [_format: "json"])
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(make_url(path), [], params: params),
      {:ok, parsed} <- Poison.Parser.parse(body) do
      {:ok, parsed}
    else
      {:error, msg} -> {:error, msg}
      err -> {:error, err}
    end
  end

  defp make_url(path), do: Content.Config.root() <> path
end
