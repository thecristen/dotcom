defmodule SiteWeb.ScheduleView.Timetable do
  alias SiteWeb.ViewHelpers, as: Helpers

  @doc """
  Displays the CR icon if given a non-nil vehicle location. Otherwise, displays nothing.
  """
  @spec timetable_location_display(Vehicles.Vehicle.t | nil) :: Phoenix.HTML.Safe.t
  def timetable_location_display(%Vehicles.Vehicle{}) do
    Helpers.svg("icon-commuter-rail-default.svg")
  end
  def timetable_location_display(_location), do: ""
end
