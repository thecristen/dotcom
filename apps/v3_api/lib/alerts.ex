defmodule V3Api.Alerts do
  @moduledoc """

  Responsible for fetching Alert data from the V3 API.

  """
  import V3Api

  def all do
    get_json("/alerts/")
  end

  def by_id(id) do
    get_json("/alerts/" <> id)
  end
end
