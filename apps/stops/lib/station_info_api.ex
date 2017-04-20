defmodule Stops.StationInfoApi do
  @moduledoc """
  Wrapper around the remote stop information service.
  """
  import Stops.StationInfo.Csv, only: [parse_row: 1]
  alias Stops.Stop

  @stations "priv/stations.csv"
  |> File.stream!
  |> CSV.decode(headers: true)
  |> Enum.map(&parse_row/1)
  |> Map.new(& {&1.id, &1})

  @spec all() :: [Stop.t]
  def all do
    Map.values(@stations)
  end

  @spec by_gtfs_id(Stop.id_t) :: Stop.t | nil
  def by_gtfs_id(id) do
    Map.get(@stations, id)
  end
end
