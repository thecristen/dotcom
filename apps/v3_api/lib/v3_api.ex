defmodule V3Api do
  use HTTPoison.Base
  require Logger

  def get_json(url, params \\ [], timeout \\ 30_000) do
    Logger.debug("V3Api.get_json url=#{url} params=#{params |> Map.new |> Poison.encode!}")
    with {time, response} <- timed_get(url, params, timeout),
         log_response(url, params, time, response),
         {:ok, %{body: body, status_code: 200}} <- response do
      body
      |> JsonApi.parse
    end
  end

  defp timed_get(url, params, timeout) do
    {time, response} = :timer.tc(fn ->
      get(url, [],
        params: params,
        timeout: timeout,
        recv_timeout: timeout)
    end)
    {time, response}
  end

  defp log_response(url, params, time, response) do
    Logger.info("V3Api.get_json_response url=#{url} " <>
      "params=#{params |> Map.new |> Poison.encode!} " <>
      log_body(response) <>
      " duration=#{time / 1000}")
  end

  defp log_body({:ok, response}) do
    "status=#{response.status_code} content_length=#{byte_size(response.body)}"
  end
  defp log_body({:error, error}) do
    ~s(status=error error="#{inspect error}")
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
