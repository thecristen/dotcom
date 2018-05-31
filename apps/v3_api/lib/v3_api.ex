defmodule V3Api do
  use HTTPoison.Base
  require Logger
  import V3Api.SentryExtra

  @default_timeout Application.get_env(:v3_api, :default_timeout)

  @spec get_json(String.t, Keyword.t) :: JsonApi.t | {:error, any}
  def get_json(url, params \\ [], opts \\ []) do
    _ = Logger.debug(fn -> "V3Api.get_json url=#{url} params=#{params |> Map.new |> Poison.encode!}" end)
    body = ""

    with opts = Keyword.merge(default_options(), opts),
         {time, response} <- timed_get(url, params, opts),
         :ok <- log_response(url, params, time, response),
         {:ok, http_response} <- response,
         {:ok, body} <- body(http_response) do
      body
      |> JsonApi.parse
      |> maybe_log_parse_error(url, params, body)
    else
      {:error, error} ->
        _ = log_response_error(url, params, body)
        {:error, error}
      error ->
        _ = log_response_error(url, params, body)
        {:error, error}
    end
  end

  defp timed_get(url, params, opts) do
    url = Keyword.fetch!(opts, :base_url) <> url
    timeout = Keyword.fetch!(opts, :timeout)
    api_key = Keyword.fetch!(opts, :api_key)

    headers = api_key_headers(api_key)

    {time, response} = :timer.tc(fn ->
      get(url, headers,
        params: params,
        timeout: timeout,
        recv_timeout: timeout)
    end)
    {time, response}
  end

  @spec maybe_log_parse_error(JsonApi.t | {:error, any}, String.t, Keyword.t, String.t) :: JsonApi.t | {:error, any}
  defp maybe_log_parse_error({:error, error}, url, params, body) do
    _ = log_response_error(url, params, body)
    {:error, error}
  end
  defp maybe_log_parse_error(response, _, _, _) do
    response
  end

  @spec log_response(String.t, Keyword.t, integer, any) :: :ok
  defp log_response(url, params, time, response) do
    entry = fn -> "V3Api.get_json_response url=#{inspect url} " <>
      "params=#{params |> Map.new |> Poison.encode!} " <>
      log_body(response) <>
      " duration=#{time / 1000}"
    end
    _ = log_context("api-response", entry)
    _ = Logger.info(entry)
    :ok
  end

  @spec log_response_error(String.t, Keyword.t, String.t) :: :ok
  defp log_response_error(url, params, body) do
    entry = fn -> "V3Api.get_json_response url=#{inspect url} " <>
      "params=#{params |> Map.new |> Poison.encode!} response=" <>
      body
    end
      _ = log_context("api-response-error", entry)
      _ = Logger.info(entry)
    :ok
  end

  defp log_body({:ok, response}) do
    "status=#{response.status_code} content_length=#{byte_size(response.body)}"
  end
  defp log_body({:error, error}) do
    ~s(status=error error="#{inspect error}")
  end

  def body(%{headers: headers, body: body}) do
    case Enum.find(
          headers,
          &String.downcase(elem(&1, 0)) == "content-encoding") do
      {_, "gzip"} ->
        {:ok, :zlib.gunzip(body)}
      _ ->
        {:ok, body}
    end
  rescue
    e in ErlangError -> {:error, e.original}
  end
  def body(other) do
    other
  end

  defp process_request_headers(headers) do
    [{"accept-encoding", "gzip"},
     {"accept", "application/vnd.api+json"}
     | headers]
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(api_key), do: [{"x-api-key", api_key}]

  defp default_options do
    [
      base_url: config(:base_url),
      api_key: config(:api_key),
      timeout: @default_timeout
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
