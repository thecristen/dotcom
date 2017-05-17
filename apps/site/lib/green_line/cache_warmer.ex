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
    start_date_fn = Keyword.get(opts, :start_date_fn, &Util.service_date/0)
    end_date_fn = Keyword.get(opts, :end_date_fn, &Schedules.Repo.end_of_rating/0)
    reset_fn = Keyword.get(opts, :reset_fn, &Site.GreenLine.Cache.reset_cache/1)

    GenServer.start_link(__MODULE__, {start_date_fn, end_date_fn, reset_fn})
  end

  def init(state) do
    send self(), :populate_caches
    {:ok, state}
  end

  def handle_info(:populate_caches, {start_date_fn, end_date_fn, reset_fn} = state) do
    reset_fn.(nil)
    populate_cache(start_date_fn.(), end_date_fn.(), reset_fn)

    Process.send_after(
      self(),
      :populate_caches,
      next_update_after(Timex.now("America/New_York"))
    )

    {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state} # no cover
  end

  def next_update_after(now) do
    tomorrow_morning =
      now
      |> Timex.shift(days: 1)
      |> Timex.beginning_of_day
      |> Timex.shift(hours: 7)

    Timex.diff(tomorrow_morning, now, :milliseconds)
  end

  defp populate_cache(date, last_date, reset_fn) do
    if Timex.before?(date, Timex.shift(last_date, days: 1)) do
      reset_fn.(date)
      populate_cache(Timex.shift(date, days: 1), last_date, reset_fn)
    end
  end
end
