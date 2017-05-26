defmodule Content.CMS.TimeRequest do
  @moduledoc false

  require Logger

  @doc """

  Wraps an HTTP call and times how long the request takes.  Returns the HTTP response.

  """
  @spec time_request(atom, String.t, String.t, Keyword.t, Keyword.t) ::
    {:ok, HTTPoison.Response.t} |
    {:error, HTTPoison.Error.t}
  def time_request(method, url, body \\ "", headers \\ [], params \\ []) do
    {time, response} = :timer.tc(HTTPoison, :request, [method, url, body, headers, [params: params]])
    log_response(time, url, params, response)
    response
  end

  defp log_response(time, url, params, response) do
    _ = Logger.info(fn ->
      params = Keyword.delete(params, :_format)
      text = case response do
               {:ok, %{status_code: code}} -> "status=#{code}"
               {:error, e} -> "status=error error=#{inspect e}"
             end
      time = time / :timer.seconds(1)
      "#{__MODULE__} response url=#{url} params=#{inspect params} #{text} duration=#{time}"
    end)
    :ok
  end
end
