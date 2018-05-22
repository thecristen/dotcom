defmodule Algolia.Analytics do
  require Logger

  @spec click(%{String.t => String.t}) :: :ok | {:error, any}
  def click(%{"objectID" => _, "position" => _, "queryID" => _} = params) do
    :algolia
    |> Application.get_env(:click_analytics_url)
    |> do_click(params)
  end
  def click(params) do
    {:error, %{reason: :bad_params, params: params}}
  end

  defp do_click("https://insights.algolia.io", _params) do
    # Algolia click tracking is not enabled on our account yet.
    # This pattern should be removed once click tracking is
    # enabled -- expected to be around mid-June 2018
    :ok
  end
  defp do_click("http" <> _ = url, params) do
    {:ok, json} = Poison.encode(params)
    url
    |> Path.join("1/searches/click")
    |> HTTPoison.post(json, post_headers())
    |> handle_click_response()
  end

  defp handle_click_response({:ok, %HTTPoison.Response{status_code: 200}}) do
    :ok
  end
  defp handle_click_response({:ok, %HTTPoison.Response{} = response}) do
    _ = Logger.warn("module=#{__MODULE__} Bad response from Algolia: #{inspect(response)}")
    {:error, response}
  end
  defp handle_click_response({:error, %HTTPoison.Error{} = response}) do
    _ = Logger.warn("module=#{__MODULE__} Error connecting to Algolia: #{inspect(response)}")
    {:error, response}
  end

  defp post_headers do
    %Algolia.Config{app_id: <<app_id::binary>>, admin: <<admin_key::binary>>} = Algolia.Config.config()
    [
      {"X-Algolia-Application-Id", app_id},
      {"X-Algolia-API-Key", admin_key},
      {"Content-Type", "application/json"}
    ]
  end
end
