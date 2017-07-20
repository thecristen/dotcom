defmodule Site.ScheduleV2Controller.Schedules do
  @moduledoc """

  Responsible for populating @schedules and @frequency_table based on parameters.

  """
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]

  require Routes.Route
  alias Routes.Route

  @impl true
  def init(_), do: []

  @impl true
  def call(%Plug.Conn{assigns: %{origin: nil}} = conn, _) do
    conn
  end
  def call(conn, []) do
    schedules = schedules(conn)
    conn
    |> assign(:schedules, schedules)
    |> assign_frequency_table(schedules)
  end

  def schedules(conn, test_override_lookup_fn \\ nil)
  def schedules(%{assigns: %{
                     date: date,
                     route: %Routes.Route{id: route_id},
                     origin: %Stops.Stop{id: origin_id},
                     destination: %Stops.Stop{id: destination_id}}},
                test_override_lookup_fn) do
    # with an origin, destination, we return pairs
    lookup_fn = test_override_lookup_fn || &Schedules.Repo.origin_destination/3
    lookup_fn.(origin_id, destination_id, date: date, route: route_id)
  end
  def schedules(%{assigns: %{
                    date: date,
                    route: %Routes.Route{id: route_id},
                    direction_id: direction_id,
                    origin: %Stops.Stop{id: origin_id}}},
                _test_override_lookup_fn) do
    # return schedules that stop at the origin
    [route_id]
    |> Schedules.Repo.by_route_ids(stop_ids: [origin_id], date: date, direction_id: direction_id)
    |> Enum.reject(&match?(%Schedules.Schedule{pickup_type: 1}, &1))
  end

  @spec assign_frequency_table(Plug.Conn.t, [{Schedules.Schedule.t, Schedules.Schedule.t}]) :: Plug.Conn.t
  def assign_frequency_table(conn, [{%Schedules.Schedule{route: %Routes.Route{type: type, id: route_id}}, _} | _] = schedules)
  when Route.subway?(type, route_id) do
    frequencies = schedules
    |> Enum.map(fn schedule -> elem(schedule, 0) end)
    |> Schedules.FrequencyList.build_frequency_list

    conn
    |> assign(:frequency_table, frequencies)
  end
  def assign_frequency_table(conn, [%Schedules.Schedule{route: %Routes.Route{type: type, id: route_id}} | _] = schedules)
  when Route.subway?(type, route_id) do
    assign(conn, :frequency_table, Schedules.FrequencyList.build_frequency_list(schedules))
  end
  def assign_frequency_table(conn, _schedules) do
    conn
  end
end
