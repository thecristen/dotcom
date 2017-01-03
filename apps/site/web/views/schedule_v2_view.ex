defmodule Site.ScheduleV2View do
  use Site.Web, :view

  defdelegate build_calendar(date, holidays, conn), to: Site.ScheduleV2.Calendar

  @doc """
  Given a list of schedules, returns a display of the route direction. Assumes all
  schedules have the same route and direction.
  """
  @spec display_direction([Schedules.Schedule.t]) :: iodata
  def display_direction([
    %Schedules.Schedule{
      route: %Routes.Route{id: route_id},
      trip: %Schedules.Trip{direction_id: direction_id}}
    | _]) do
    [direction(direction_id, route_id), " to"]
  end
  def display_direction([]), do: ""

  def update_schedule_url(conn, query) do
    conn
    |> Site.ViewHelpers.update_query(query)
    |> Map.pop("route")
    |> do_update_schedule_url(conn)
  end

  defp do_update_schedule_url({nil, new_query}, conn), do: green_path(conn, :green, new_query |> Enum.into([]))
  defp do_update_schedule_url({route, new_query}, conn), do: bus_path(conn, :show, route, new_query |> Enum.into([]))

  @doc "Subtract one month from given date"
  @spec decrement_month(Date.t) :: Date.t
  def decrement_month(date), do: shift_month(date, -1)

  @doc "Add one month from given date"
  @spec add_month(Date.t) :: Date.t
  def add_month(date), do: shift_month(date, 1)

  @spec shift_month(Date.t, integer) :: Date.t
  defp shift_month(date, delta) do
    date
    |> Timex.beginning_of_month
    |> Timex.shift(months: delta)
  end

  @doc """
  Class for the previous month link in the date picker. If the given date is during the current month
  or before it is disabled; otherwise it's left as is.
  """
  @spec previous_month_class(Date.t) :: String.t
  def previous_month_class(date) do
    if Util.today.month == date.month or Timex.before?(date, Util.today) do
      " disabled"
    else
      ""
    end
  end

  def reverse_direction_opts(origin, dest, route_id, direction_id) do
    new_origin = dest || origin
    new_dest = dest && origin
    [trip: nil, direction_id: direction_id, route: route_id]
    |> Keyword.merge(
      if Schedules.Repo.stop_exists_on_route?(new_origin, route_id, direction_id) do
        [dest: new_dest, origin: new_origin]
      else
        [dest: nil, origin: nil]
      end
    )
  end

  def stop_info_link(stop) do
    do_stop_info_link(Stops.Repo.get(stop.id))
  end

  defp do_stop_info_link(%{id: id, name: name}) do
    title = "View stop information for #{name}"
    body = ~e(
      <%= svg_icon %SvgIcon{icon: :map} %>
      <span class="sr-or-no-js"> <%= title %>
    )

    link(
      to: stop_path(Site.Endpoint, :show, id),
      class: "station-info-link",
      data: [
        toggle: "tooltip"
      ],
      title: title,
      do: body)
  end
end
