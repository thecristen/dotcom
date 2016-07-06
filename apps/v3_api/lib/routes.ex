defmodule V3Api.Routes do
  @moduledoc """

  Responsible for fetching Route data from the V3 API.

  """
  import V3Api

  def all do
    get_json("/routes/")
  end

  def by_type(type) do
    get_json("/routes/", type: type)
  end

  def by_stop(stop_id) do
    get_json("/routes/", stop: stop_id)
  end
end
