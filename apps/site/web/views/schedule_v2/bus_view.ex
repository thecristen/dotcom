defmodule Site.ScheduleV2.BusView do
  use Site.Web, :view

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

end
