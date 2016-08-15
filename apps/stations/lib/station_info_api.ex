defmodule Stations.StationInfoApi do
  @moduledoc """
  Wrapper around the remote station information service.
  """
  use HTTPoison.Base

  def all do
    do_all(get("/stations/"), nil)
  end

  def by_gtfs_id(gtfs_id) do
    with {:ok, response} <- get("/stations/", [], params: [gtfs_id: gtfs_id]),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end

  defp do_all({:ok, %{body: body, status_code: 200}}, acc) do
    parsed = body
    |> JsonApi.parse

    new_acc = case acc do
                nil ->
                  parsed
                acc ->
                  JsonApi.merge(parsed, acc)
              end

    case parsed.links["next"] do
      nil -> new_acc
      link -> do_all(get(link), new_acc)
    end
  end

  defp process_url(url) do
    base_url = case Application.get_env(:stations, :base_url) do
                 {:system, envvar, default} ->
                   System.get_env(envvar) || default
                 value -> value
               end
    base_url <> url
  end
end
