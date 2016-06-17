defmodule V3Api.Alerts do
  @moduledoc """

  Responsible for fetching Alert data from the V3 API.

  """
  import V3Api

  def all do
    get_json("/alerts/")
  end
end
