defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2.BusView

  describe "display_direction/1" do
    test "given no schedules, returns no content" do
      assert display_direction([]) == ""
    end

    test "given a non-empty list of schedules, displays the direction of the first schedule's route" do
      schedules = [
        %Schedules.Schedule{route: %Routes.Route{id: "Red"}, trip: %Schedules.Trip{direction_id: 1}}
      ]
      assert schedules |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end
end
