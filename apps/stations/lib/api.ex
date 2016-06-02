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
      |> Enum.map(&(parse(&1, parsed)))
      |> List.first
    end
  end

  defp do_all({:ok, %{body: parsed}}, acc) do
    new_items = for item <- parsed["data"] do
      parse(item, parsed)
    end

    new_acc = new_items ++ acc

    case parsed["links"]["next"] do
      nil -> new_acc
      link -> do_all(get(link), new_acc)
    end
  end

  defp parse(item, parsed) do
    item
    |> parse_station
    |> include_parking(item, parsed)
  end

  defp parse_station(%{"attributes" => attributes}) do
    %Station{
      id: attributes["gtfs_id"],
      name: attributes["name"],
      address: attributes["address"],
      note: attributes["note"],
      accessibility: attributes["accessibility"]
    }
  end

  defp include_parking(station, item, parsed) do
    parkings = case item["relationships"]["parkings"]["data"] do
                 nil ->
                   []
                 parkings ->
                   parkings
                   |> Enum.flat_map(&(match_included(&1, parsed)))
                   |> Enum.map(&(parse_parking(&1, parsed)))
               end
    %Station{station | parkings: parkings}
  end

  defp parse_parking(%{"attributes" => attributes, "relationships" => relationships}, parsed) do
    %Station.Parking{
      type: attributes["type"],
      spots: attributes["spots"],
      rate: attributes["rate"],
      note: attributes["note"]
    }
    |> include_manager(relationships["manager"], parsed)
  end

  defp include_manager(parking, nil, _) do
    parking
  end
  defp include_manager(parking, %{"data" => data}, parsed) do
    case match_included(data, parsed) do
      [manager] ->
        %Station.Parking{parking | manager: parse_manager(manager)}
      _ -> parking
    end
  end

  defp parse_manager(%{"attributes" => attributes}) do
    %Station.Manager{
      name: attributes["name"],
      website: attributes["website"],
      phone: attributes["phone"],
      email: attributes["email"]
    }
  end

  defp match_included(nil, _) do
    []
  end
  defp match_included(%{"type" => type, "id" => id}, %{"included" => included}) do
    included
    |> Enum.filter(&(&1["type"] == type && &1["id"] == id))
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
