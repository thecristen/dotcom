defmodule V3Api do
  use HTTPoison.Base
  require Logger

  def get_json(url, params \\ [], timeout \\ 30_000) do
    Logger.debug("V3Api.get_json url=#{url} params=#{params |> Map.new |> Poison.encode!}")
    with {time, response} <- timed_get(url, params, timeout),
         Logger.info("V3Api.get_json_response url=#{url} params=#{params |> Map.new |> Poison.encode!} status=#{response.status_code} content_length=#{byte_size(response.body)} duration=#{time / 1000}"),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end

  defp timed_get(url, params, timeout) do
    {time, {:ok, response}} = :timer.tc(fn ->
      get(url, [],
        params: params,
        timeout: timeout,
        recv_timeout: timeout)
    end)
    {time, response}
  end

  defp process_url(url) do
    base_url = case Application.get_env(:v3_api, :base_url) do
                 {:system, envvar, default} ->
                   System.get_env(envvar) || default
                 value -> value
               end
    base_url <> url
  end
end
