defmodule News.Fetch do
  use GenServer
  require Logger

  @refetch_timeout :timer.hours(3)

  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  def init(url) do
    # immediate timeout
    {:ok, url, 0}
  end

  def handle_info(:timeout, url) do
    _ = Logger.debug("#{__MODULE__} fetching")
    :ok = url
    |> HTTPoison.get
    |> unzip_response
    |> update_repo

    {:noreply, url, @refetch_timeout}
  end

  defp unzip_response({:ok, %{status_code: 200, body: body}}) do
    :zip.unzip(body, [:memory])
  end
  defp unzip_response(other) do
    other
  end

  def update_repo({:ok, files}) do
    News.Repo.Ets.update(files)
  end
  def update_repo(other) do
    _ = Logger.info("#{__MODULE__} unknown response for news: #{inspect other}")
  end
end
