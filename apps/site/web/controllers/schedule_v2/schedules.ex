defmodule Site.ScheduleV2Controller.Schedules do
  @moduledoc """

  Responsible for populating @schedules and @direction_id based on parameters.

  """
  import Plug.Conn, only: [assign: 3]
  alias Site.ScheduleController.Query

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{origin: nil}} = conn, _) do
    conn
  end
  def call(conn, []) do
    schedules = schedules(conn)
    conn
    |> assign(:schedules, schedules)
    |> assign_direction_id(schedules)
    |> assign_frequency_table(schedules)
  end

  def schedules(%{assigns: %{
                     date: date,
                     route: %Routes.Route{type: route_type},
                     origin: %Stops.Stop{id: origin_id},
                     destination: %Stops.Stop{id: destination_id}}}) do
    # with an origin, destination, we return pairs
    origin_destination_pairs = Schedules.Repo.origin_destination(origin_id, destination_id, date: date)

    Enum.filter(origin_destination_pairs, &match?({%Schedules.Schedule{route: %{type: ^route_type}}, _}, &1))
  end
  def schedules(conn) do
    # otherwise, fall back to the generated query
    conn
    |> Query.schedule_query
    |> Schedules.Repo.all
  end

  @spec assign_frequency_table(Plug.Conn.t, [{Schedules.Schedule.t, Schedules.Schedule.t}]) :: Plug.Conn.t
  def assign_frequency_table(conn, [{%Schedules.Schedule{route: %Routes.Route{type: type}}, _} | _] = schedules)
  when type in [0, 1] do
    frequencies = schedules
    |> Enum.map(fn schedule -> elem(schedule, 0) end)
    |> TimeGroup.frequency_by_time_block

    conn
    |> assign(:frequency_table, frequencies)
  end
  def assign_frequency_table(conn, [%Schedules.Schedule{route: %Routes.Route{type: type}} | _] = schedules)
  when type in [0, 1] do
    frequencies = schedules
    |> TimeGroup.frequency_by_time_block

    conn
    |> assign(:frequency_table, frequencies)
  end
  def assign_frequency_table(conn, _schedules) do
    conn
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
