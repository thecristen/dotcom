defmodule Stations.Api do
  @moduledoc """
  Wrapper around the remote station information service.
  """
  use HTTPoison.Base
  alias Stations.Station

  @spec all :: [Station.t]
  def all do
    do_all(get("/stations/"), [])
  end

  @spec by_gtfs_id(String.t) :: Station.t | nil
  def by_gtfs_id(gtfs_id) do
    with {:ok, response} <- get("/stations/", [], params: [gtfs_id: gtfs_id]),
         %{body: parsed, status_code: 200} <- response do
      parsed["data"]
      |> Enum.map(&parse/1)
      |> List.first
    end
  end

  defp do_all({:ok, %{body: parsed}}, acc) do
    new_items = parsed["data"]
    |> Enum.map(&parse/1)

    new_acc = new_items ++ acc

    case parsed["links"]["next"] do
      nil -> new_acc
      link -> do_all(get(link), new_acc)
    end
  end

  defp parse(item) do
    %Station{
      id: item["attributes"]["gtfs_id"],
      name: item["attributes"]["name"]
    }
  end

  defp process_url(url) do
    base_url = Application.get_env(:stations, :base_url)
    base_url <> url
  end

  defp process_response_body(body) do
    {:ok, parsed} = Poison.Parser.parse(body)
    parsed
  end
end
