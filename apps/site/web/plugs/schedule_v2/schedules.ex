defmodule Site.Plugs.ScheduleV2.Schedules do
  @moduledoc """

  Responsible for populating @schedules, @show_all_schedules, and @direction_id based on parameters.

  """
  import Plug.Conn, only: [assign: 3]
  alias Site.ScheduleController.Query

  def init([]), do: []

  def call(conn, []) do
    all_schedules = schedules(conn)
    {filtered_schedules, conn} = filtered_schedules(all_schedules, conn)

    conn
    |> assign(:all_schedules, all_schedules)
    |> assign(:schedules, filtered_schedules)
    |> assign_direction_id(filtered_schedules)
  end

  def schedules(%{assigns: %{
                     date: date,
                     origin: origin,
                     destination: dest}}) when is_binary(origin) and is_binary(dest) do
    # with an origin, destination, we return pairs
    Schedules.Repo.origin_destination(origin, dest, date: date)
  end
  def schedules(conn) do
    # otherwise, fall back to the generated query
    conn
    |> Query.schedule_query
    |> Schedules.Repo.all
  end

  @doc """

  Given a list of schedules and a %Plug.Conn, return a tuple of {filtered_schedules, conn}.

  This checks @show_all_schedules, and if true returns all of the schedules.  If false, tries to filter
  the schedule for the current time, and if not all the schedules are in the past, returns the filtered list.
  If the date filtering removed all the schedules, set @show_all to true and return the full list.
  """
  def filtered_schedules(schedules, %{assigns: %{show_all_schedules: show_all_schedules}} = conn) do
    schedules
    |> upcoming_schedules(show_all_schedules)
    |> possibly_open_schedules(schedules, conn)
  end

  def assign_direction_id(conn, schedules) do
    case direction_id(schedules) do
      nil -> conn # don't update
      id -> assign(conn, :direction_id, id)
    end
  end

  defp upcoming_schedules(schedules, true) do
    schedules
  end
  defp upcoming_schedules(schedules, false) do
    # keep the last entry before the current time
    case Enum.find_index(schedules, &after_now?/1) do
      nil -> []
      index -> Enum.drop(schedules, index - 1)
    end
  end

  defp possibly_open_schedules([], all_schedules, conn) do
    {all_schedules, assign(conn, :show_all_schedules, true)}
  end
  defp possibly_open_schedules(schedules, _, conn) do
    {schedules, conn}
  end

  defp after_now?({_, arrival}) do
    after_now?(arrival)
  end
  defp after_now?(%Schedules.Schedule{time: time}) do
    Timex.after?(time, Util.now())
  end

  defp direction_id([]) do
    nil
  end
  defp direction_id([{departure, _} | _]) do
    direction_id([departure])
  end
  defp direction_id([%Schedules.Schedule{trip: %{direction_id: direction_id}} | _]) do
    direction_id
  end
end
