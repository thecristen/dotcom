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
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
      |> (fn parsed -> parsed.data end).()
      |> Enum.map(&parse_station/1)
      |> List.first
    end
  end

  defp do_all({:ok, %{body: body, status_code: 200}}, acc) do
    parsed = body
    |> JsonApi.parse

    new_items = parsed.data
    |> Enum.map(&parse_station/1)

    new_acc = new_items ++ acc

    case parsed.links["next"] do
      nil -> new_acc
      link -> do_all(get(link), new_acc)
    end
  end

  defp parse_station(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Station{
      id: attributes["gtfs_id"],
      name: attributes["name"],
      address: attributes["address"],
      note: attributes["note"],
      accessibility: attributes["accessibility"],
      parkings: Enum.map(relationships["parkings"], &parse_parking/1)
    }
  end

  defp parse_parking(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Station.Parking{
      type: attributes["type"],
      spots: attributes["spots"],
      rate: attributes["rate"],
      note: attributes["note"],
      manager: parse_manager(relationships["manager"])
    }
  end

  defp parse_manager([%JsonApi.Item{attributes: attributes}]) do
    %Station.Manager{
      name: attributes["name"],
      website: attributes["website"],
      phone: attributes["phone"],
      email: attributes["email"]
    }
  end
  defp parse_manager([]) do
    nil
  end

  defp process_url(url) do
    base_url = Application.get_env(:stations, :base_url)
    base_url <> url
  end
end
