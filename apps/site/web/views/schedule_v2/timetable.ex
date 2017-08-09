defmodule Site.ScheduleV2View.Timetable do
  use Site.Web, :view

  @doc """
  Displays the CR icon if given a non-nil vehicle location. Otherwise, displays nothing.
  """
  @spec timetable_location_display(Vehicles.Vehicle.t | nil) :: Phoenix.HTML.Safe.t
  def timetable_location_display(%Vehicles.Vehicle{}) do
    svg_icon %SvgIcon{icon: :commuter_rail, class: "icon-small", show_tooltip?: false}
  end
  def timetable_location_display(_location), do: ""
end
