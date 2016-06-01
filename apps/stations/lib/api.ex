defmodule Stations.Api do
  @moduledoc """
  Wrapper around the remote station information service.
  """
  use HTTPoison.Base
  alias Stations.Station

  @spec by_gtfs_id(String.t) :: Station.t | nil
  def by_gtfs_id(gtfs_id) do
    with {:ok, response} <- get("/stations/", [], params: [gtfs_id: gtfs_id]),
         %{body: body, status_code: 200} <- response,
         {:ok, parsed} <- Poison.Parser.parse(body) do
      case parsed["data"] do
        [] ->
          nil
        [item] ->
          %Station{
            gtfs_id: item["attributes"]["gtfs_id"],
            name: item["attributes"]["name"]
          }
      end
    end
  end

  defp process_url(url) do
    base_url = Application.get_env(:stations, :base_url)
    base_url <> url
  end
end
