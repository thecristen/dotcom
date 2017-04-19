defmodule Content.CMS.TimeRequest do
  @moduledoc false

  require Logger

  @doc """

  Wraps an HTTP call and times how long the request takes.  Returns the HTTP response.

  """
  @spec time_request(String.t, Keyword.t) :: HTTPoison.Response.t
  def time_request(url, params) do
    {time, response} = :timer.tc(HTTPoison, :get, [url, [], [params: params]])
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
