defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS
  require Logger

  def view(path, params \\ []) do
    params = Keyword.merge(params, [_format: "json"])
    with {:ok, url} <- make_url(path),
      {time, response} <- :timer.tc(HTTPoison, :get, [url, [], [params: params]]),
           log_response(time, url, params, response),
      {:ok, %{status_code: 200, body: body}} <- response,
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

  defp log_response(time, url, params, response) do
    _ = Logger.info(fn ->
      params = Keyword.delete(params, :_format)
      text = case response do
               {:ok, %{status_code: code}} -> "status=#{code}"
               {:error, e} -> "status=error error=#{inspect e}"
             end
      time = time / :timer.seconds(1)
      "Content.CMS.HTTPClient_response url=#{url} params=#{inspect params} #{text} duration=#{time}"
    end)
    :ok
  end
end
