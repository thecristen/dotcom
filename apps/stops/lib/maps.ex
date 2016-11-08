defmodule Stops.Maps do
  use HTTPoison.Base
  use RepoCache, ttl: :timer.hours(12)

  def by_name(stop_name) do
    cache stop_name, fn stop_name ->
      case head(stop_name) do
        {:ok, %{status_code: 200}} -> process_url(stop_name)
        {:ok, %{status_code: 404}} -> ""
        _ -> nil # don't cache
      end
    end
  end

  defp process_url("North Station"), do: process_url("N. Station")
  defp process_url(name) do
    "http://www.mbta.com/uploadedfiles/services/subway/#{name} Neighborhood Map.pdf" |> URI.encode
  end
end
