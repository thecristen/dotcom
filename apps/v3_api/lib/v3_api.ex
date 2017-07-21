defmodule V3Api do
  use HTTPoison.Base
  require Logger
  import V3Api.SentryExtra

  @spec get_json(String.t, Keyword.t) :: JsonApi.t | {:error, any}
  def get_json(url, params \\ [], opts \\ []) do
    _ = Logger.debug("V3Api.get_json url=#{url} params=#{params |> Map.new |> Poison.encode!}")
    body = ""
    with opts = Keyword.merge(default_options(), opts),
         {time, response} <- timed_get(url, params, opts),
         :ok <- log_response(url, params, time, response),
         {:ok, http_response} <- response,
         {:ok, body} <- body(http_response) do
      data = JsonApi.parse(body)
      case data do
        {:error, _} ->
          _ = log_reponse_error(url, params, body)
          data
        _ -> data
      end
    else
      {:error, error} ->
        _ = log_reponse_error(url, params, body)
        {:error, error}
      error ->
        _ = log_reponse_error(url, params, body)
        {:error, error}
    end
  end

  defp timed_get(url, params, opts) do
    url = Keyword.fetch!(opts, :base_url) <> url
    timeout = Keyword.fetch!(opts, :timeout)
    params = add_api_key(params, opts)
    {time, response} = :timer.tc(fn ->
      get(url, [],
        params: params,
        timeout: timeout,
        recv_timeout: timeout)
    end)
    {time, response}
  end

  @spec log_response(String.t, Keyword.t, integer, any) :: :ok
  defp log_response(url, params, time, response) do
    entry = "V3Api.get_json_response url=#{url} " <>
      "params=#{params |> Map.new |> Poison.encode!} " <>
      log_body(response) <>
      " duration=#{time / 1000}"
    log_context("api-response", entry)
    _ = Logger.info(entry)
    :ok
  end

  @spec log_reponse_error(String.t, Keyword.t, String.t) :: :ok
  defp log_reponse_error(url, params, body) do
    entry = "V3Api.get_json_response url=#{url} " <>
      "params=#{params |> Map.new |> Poison.encode!} " <>
      body
      log_context("api-response-error", entry)
      _ = Logger.info(entry)
    :ok
  end

  defp log_body({:ok, response}) do
    "status=#{response.status_code} content_length=#{byte_size(response.body)}"
  end
  defp log_body({:error, error}) do
    ~s(status=error error="#{inspect error}")
  end

  defp body(%{headers: headers, body: body}) do
    case Enum.find(
          headers,
          &String.downcase(elem(&1, 0)) == "content-encoding") do
      {_, "gzip"} ->
        {:ok, :zlib.gunzip(body)}
      _ ->
        {:ok, body}
    end
  end
  defp body(other) do
    other
  end

  defp process_request_headers(headers) do
    put_in headers[:"accept-encoding"], "gzip"
  end

  defp add_api_key(params, opts) do
    case Keyword.fetch!(opts, :api_key) do
      nil ->
        params
      key ->
        Keyword.put(params, :api_key, key)
    end
  end

  defp default_options do
    [
      base_url: config(:base_url),
      api_key: config(:api_key),
      timeout: 30_000
    ]
  end

  defp config(key) do
    case Application.get_env(:v3_api, key) do
      {:system, envvar, default} ->
        System.get_env(envvar) || default
      {:system, envvar} ->
        System.get_env(envvar)
      value -> value
    end
  end
end
