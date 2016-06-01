defmodule Stations.Station do
  @moduledoc """
  Domain model for a station.
  """
  defstruct [:id, :name, :note, :accessibility, :address]
end
