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

  def by_stop(stop_id, opts \\ []) do
    opts = put_in opts[:stop], stop_id
    get_json("/routes/", opts)
  end
end
