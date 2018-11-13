defmodule SiteWeb.ScheduleView.Timetable do
  alias SiteWeb.ViewHelpers, as: Helpers

  import Phoenix.HTML.Tag, only: [tag: 2, content_tag: 2, content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]

  @type vehicle_tooltip_key :: {Schedules.Trip.id_t, Stops.Stop.id_t}

  @doc """
  Displays the CR icon if given a non-nil vehicle location. Otherwise, displays nothing.
  """
  @spec timetable_location_display(Vehicles.Vehicle.t | nil) :: Phoenix.HTML.Safe.t
  def timetable_location_display(%Vehicles.Vehicle{}) do
    Helpers.svg("icon-commuter-rail-default.svg")
  end
  def timetable_location_display(_location), do: ""

  @spec timetable_tooltip(VehicleTooltip.t, vehicle_tooltip_key, boolean, boolean) :: nil | Phoenix.HTML.Safe.t
  def timetable_tooltip(vehicle_tooltips, vehicle_tooltip_key, early_departure?, flag_stop?) do
    tooltips = [
      vehicle_tooltip(vehicle_tooltips, vehicle_tooltip_key),
      early_departure(early_departure?),
      flag_stop(flag_stop?)
    ]
    combine_tooltips(tooltips)
  end

  defp combine_tooltips([[], [], []]) do
    nil
  end
  defp combine_tooltips([[], early_departure_tooltip, flag_tooltip]) do
    :div
    |> content_tag([early_departure_tooltip, flag_tooltip])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end
  defp combine_tooltips([vehicle_tooltip, [], []]) do
    vehicle_tooltip
  end
  defp combine_tooltips([vehicle_tooltip, early_departure_tooltip, flag_tooltip]) do
    :div
    |> content_tag([vehicle_tooltip, tag(:hr, class: "tooltip-divider"), early_departure_tooltip, flag_tooltip])
    |> safe_to_string
    |> String.replace(~s("), ~s('))
  end

  defp vehicle_tooltip(vehicle_tooltips, vehicle_tooltip_key) do
    if Map.has_key?(vehicle_tooltips, vehicle_tooltip_key) do
      VehicleHelpers.tooltip(vehicle_tooltips[vehicle_tooltip_key])
    else
      []
    end
  end

  defp early_departure(true), do: content_tag(:p, "Early Departure Stop", class: "stop-tooltip")
  defp early_departure(false), do: []

  defp flag_stop(true), do: content_tag(:p, "Flag Stop", class: "stop-tooltip")
  defp flag_stop(false), do: []
end
