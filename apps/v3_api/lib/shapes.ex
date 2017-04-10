defmodule V3Api.Shapes do
  @moduledoc """

  Responsible for fetching Stop data from the V3 API.

  """
  import V3Api

  def all(params \\ []) do
    get_json("/shapes/", params)
  end
end
