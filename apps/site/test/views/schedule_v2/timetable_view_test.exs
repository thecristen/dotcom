defmodule Site.ScheduleV2.TimetableViewTest do
  use ExUnit.Case, async: true

  import Site.ScheduleV2View.Timetable

  describe "timetable_location_display/1" do
    test "given nil, returns the empty string" do
      assert timetable_location_display(nil) == ""
    end

    test "otherwise, displays the CR icon" do
      for status <- [:in_transit, :incoming, :stopped] do
        icon = %Site.Components.Icons.SvgIcon{icon: :commuter_rail, class: "icon-small", show_tooltip?: false}
        rendered_icon = Site.PageView.svg_icon(icon)
        assert timetable_location_display(%Vehicles.Vehicle{status: status}) == rendered_icon
      end
    end
  end
end
