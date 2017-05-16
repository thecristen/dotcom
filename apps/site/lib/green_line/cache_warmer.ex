defmodule Site.GreenLine.CacheWarmer do
  @moduledoc """
  This supervised GenServer populates the GreenLine.DateAgent caches.
  By default, it will ensure an agent is running for every date from
  Util.service_date() until Schedules.Repo.end_of_rating().

  It then schedules a message to itself to update all these agents at
  about 7am ET the next morning.
  """

  use GenServer

  def start_link(opts \\ []) do
    start_date = Keyword.get(opts, :start_date, Util.service_date())
    end_date = Keyword.get(opts, :end_date, Schedules.Repo.end_of_rating())
    reset_fn = Keyword.get(opts, :reset_fn, &Site.GreenLine.Cache.reset_cache/1)

    GenServer.start_link(__MODULE__, {start_date, end_date, reset_fn})
  end

  def init(state) do
    send self(), :populate_caches
    {:ok, state}
  end

  def handle_info(:populate_caches, {start_date, end_date, reset_fn} = state) do
    reset_fn.(nil)
    populate_cache(start_date, end_date, reset_fn)
    schedule_next_update()

    {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state} # no cover
  end

  defp populate_cache(date, last_date, reset_fn) do
    if Timex.before?(date, Timex.shift(last_date, days: 1)) do
      reset_fn.(date)
      populate_cache(Timex.shift(date, days: 1), last_date, reset_fn)
    end
  end

  defp schedule_next_update do
    now = Timex.now("America/New_York")

    tomorrow_morning =
      now
      |> Timex.shift(days: 1)
      |> Timex.beginning_of_day
      |> Timex.shift(hours: 7)

    wait_until = Timex.diff(tomorrow_morning, now, :milliseconds)

    Process.send_after(self(), :populate_caches, wait_until)
  end
end
