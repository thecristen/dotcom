defmodule Site.ScheduleV2Controller.Schedules do
  @moduledoc """

  Responsible for populating @schedules and @direction_id based on parameters.

  """
  import Plug.Conn, only: [assign: 3]
  alias Site.ScheduleController.Query

  def init([]), do: []

  def call(conn, []) do
    schedules = schedules(conn)
    conn
    |> assign(:schedules, schedules)
    |> assign_direction_id(schedules)
  end

  def schedules(%{assigns: %{
                     date: date,
                     origin: %Stops.Stop{id: origin_id},
                     destination: %Stops.Stop{id: destination_id}}}) do
    # with an origin, destination, we return pairs
    Schedules.Repo.origin_destination(origin_id, destination_id, date: date)
  end
  def schedules(conn) do
    # otherwise, fall back to the generated query
    conn
    |> Query.schedule_query
    |> Schedules.Repo.all
  end

  def assign_direction_id(conn, schedules) do
    case direction_id(schedules) do
      nil -> conn # don't update
      id -> assign(conn, :direction_id, id)
    end
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
