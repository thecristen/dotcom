defmodule TripPlanIntegrationTest do
  use SiteWeb.IntegrationCase
  import Wallaby.Query

  @leave_now css("#leave-now")
  @depart css("#depart")
  @arrive css("#arrive")
  @datepicker css("#trip-plan-datepicker")

  describe "trip plan form" do
    @tag :wallaby
    test "datepicker starts hidden and shows when depart/arrive are clicked", %{session: session} do
      session =
        session
        |> visit("/trip-planner")

      refute visible?(session, @datepicker)
      click(session, @depart)
      assert visible?(session, @datepicker)
      click(session, @leave_now)
      refute visible?(session, @datepicker)
      click(session, @arrive)
      assert visible?(session, @datepicker)
    end
  end
end
