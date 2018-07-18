defmodule TripPlanIntegrationTest do
  use SiteWeb.IntegrationCase
  import Wallaby.Query

  @leave_now css("#leave-now")
  @depart css("#depart")
  @arrive css("#arrive")
  @accordion css("#trip-plan-accordion-title")
  @datepicker css("#trip-plan-datepicker")
  @to css("#to")
  @from css("#from")
  @reverse_button css("#trip-plan-reverse-control")

  describe "trip plan form" do
    @tag :wallaby
    test "datepicker starts hidden and shows when depart/arrive are clicked", %{session: session} do
      session =
        session
        |> visit("/trip-planner")

      click(session, @accordion)
      refute visible?(session, @datepicker)
      click(session, @depart)
      assert visible?(session, @datepicker)
      click(session, @leave_now)
      refute visible?(session, @datepicker)
      click(session, @arrive)
      assert visible?(session, @datepicker)
    end

    @tag :wallaby
    test "reverse button swaps to and from", %{session: session} do
      session = session
                |> visit("/trip-planner")
                |> fill_in(@from, with: "A")
                |> fill_in(@to, with: "B")

      assert Browser.has_value?(session, @from, "A")
      assert Browser.has_value?(session, @to, "B")

      click(session, @reverse_button)

      assert Browser.has_value?(session, @from, "B")
      assert Browser.has_value?(session, @to, "A")
    end

    @tag :wallaby
    test "departure options update accordion title", %{session: session} do
      session =
        session
        |> visit("/trip-planner")

      click(session, @accordion)
      refute visible?(session, @datepicker)
      assert Browser.text(session, @accordion) =~ "Leave now"
      click(session, @depart)
      assert Browser.text(session, @accordion) =~ "Depart at"
      click(session, @arrive)
      assert Browser.text(session, @accordion) =~ "Arrive by"
    end

    @tag :wallaby
    test "departure hour updates accordion title", %{session: session} do
      session =
        session
        |> visit("/trip-planner")
        |> click(@accordion)
        |> click(@arrive)

      Browser.fill_in(session, css("#plan_date_time_hour"), with: 10)
      click(session, css("#main"))
      assert Browser.text(session, @accordion) =~ "Arrive by 10:"
    end
  end
end
