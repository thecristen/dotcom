defmodule Stations.V3Api do
  use HTTPoison.Base
  def by_gtfs_id(gtfs_id) do
    with {:ok, response} <- get("/stops/#{URI.encode(gtfs_id, &URI.char_unreserved?/1)}"),
         %{body: body, status_code: 200} <- response do
      body
      |> JsonApi.parse
    end
  end

  defp process_url(url) do
    base_url = Application.get_env(:stations, :v3_url)
    base_url <> url
  end
end
