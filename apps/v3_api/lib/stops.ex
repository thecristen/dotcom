defmodule V3Api.Stops do
  @moduledoc """

  Responsible for fetching Stop data from the V3 API.

  """
  import V3Api

  def by_gtfs_id(gtfs_id) do
    with {:ok, response} <- get("/stops/#{URI.encode(gtfs_id, &URI.char_unreserved?/1)}"),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end
end
