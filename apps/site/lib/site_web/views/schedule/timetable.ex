defmodule SiteWeb.ScheduleView.Timetable do
  alias Schedules.Schedule
  alias SiteWeb.ViewHelpers, as: Helpers
  alias Stops.Stop

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

  @spec stop_accessibility_icon(Stop.t) :: [Phoenix.HTML.Safe.t]
  def stop_accessibility_icon(stop) do
    cond do
      Stop.accessible?(stop) ->
        [
          content_tag(
            :span,
            Helpers.svg("icon-accessibility.svg"),
            aria: [hidden: "true"],
            class: "m-timetable__access-icon",
            data: [toggle: "tooltip"],
            title: "Accessible"
          ),
          content_tag(:span, "Accessible", [class: "sr-only"])
        ]
      Stop.accessibility_known?(stop) ->
        [
          content_tag(:span, "Not accessible", [class: "sr-only"])
        ]
      true ->
        [
          content_tag(:span, "May not be accessible", [class: "sr-only"])
        ]
    end
  end

  @spec stop_row_class(integer) :: String.t
  def stop_row_class(idx) do
    ["js-tt-row", "m-timetable__row"]
    |> do_stop_row_class(idx)
    |> Enum.join(" ")
  end

  @spec do_stop_row_class([String.t], integer) :: [String.t]
  defp do_stop_row_class(class_list, 0) do
    ["m-timetable__row--first" | class_list]
  end
  defp do_stop_row_class(class_list, idx) when rem(idx, 2) == 1 do
    ["m-timetable__row--gray" | class_list]
  end
  defp do_stop_row_class(class_list, _) do
    class_list
  end

  @spec cell_flag_class(Schedule.t) :: String.t
  def cell_flag_class(%Schedule{flag?: true}), do: " m-timetable__cell--flag-stop"
  def cell_flag_class(%Schedule{early_departure?: true}), do: " m-timetable__cell--early-departure"
  def cell_flag_class(_), do: ""

  @spec cell_via_class(String.t | nil) :: String.t
  def cell_via_class(nil), do: ""
  def cell_via_class(<<_::binary>>), do: " m-timetable__cell--via"
end
