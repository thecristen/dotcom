defmodule Site.ScheduleV2Controller.Schedules do
  @moduledoc """

  Responsible for populating @schedules and @frequency_table based on parameters.

  """
  import Plug.Conn, only: [assign: 3]

  require Routes.Route
  alias Routes.Route

  def init(_), do: []

  def call(%Plug.Conn{assigns: %{origin: nil}} = conn, _) do
    conn
  end
  def call(conn, []) do
    schedules = schedules(conn)
    conn
    |> assign(:schedules, schedules)
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
  def schedules(%{assigns: %{
                    date: date,
                    route: %Routes.Route{id: route_id},
                    direction_id: direction_id,
                    origin: %Stops.Stop{id: origin_id}}}) do
    # return schedules that stop at the origin
    [stop: origin_id, route: route_id, date: date, direction_id: direction_id]
    |> Schedules.Repo.all
    |> Enum.reject(&match?(%Schedules.Schedule{pickup_type: 1}, &1))
  end

  @spec assign_frequency_table(Plug.Conn.t, [{Schedules.Schedule.t, Schedules.Schedule.t}]) :: Plug.Conn.t
  def assign_frequency_table(conn, [{%Schedules.Schedule{route: %Routes.Route{type: type}}, _} | _] = schedules)
  when Route.subway?(type) do
    frequencies = schedules
    |> Enum.map(fn schedule -> elem(schedule, 0) end)
    |> Schedules.FrequencyList.build_frequency_list

    conn
    |> assign(:frequency_table, frequencies)
  end
  def assign_frequency_table(conn, [%Schedules.Schedule{route: %Routes.Route{type: type}} | _] = schedules)
  when Route.subway?(type) do
    assign(conn, :frequency_table, Schedules.FrequencyList.build_frequency_list(schedules))
  end
  def assign_frequency_table(conn, _schedules) do
    conn
  end
end
