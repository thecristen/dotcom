defmodule Site.ScheduleV2.CommuterRailViewTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2.CommuterRailView

  describe "offset_schedules/1" do
    test "drops a number of schedules as assigned in the conn, and takes num_schedules() more", %{conn: conn} do
      assert offset_schedules(0..10, assign(conn, :offset, 2)) == [2, 3, 4, 5, 6, 7]
    end
  end

  defp build_link(offset, link_fn) do
    :get
    |> build_conn("/schedules_v2/CR-Lowell")
    |> fetch_query_params
    |> assign(:all_schedules, Enum.to_list(0..10))
    |> assign(:offset, offset)
    |> link_fn.()
    |> Phoenix.HTML.safe_to_string
  end

  describe "earlier_link/1" do
    test "shows a link to update the offset parameter" do
      result = build_link(3, &earlier_link/1)

      assert result =~ "Show earlier times"
      refute result =~ "disabled"
    end

    test "disables the link if the current offset is 0" do
      result = build_link(0, &earlier_link/1)
      assert result =~ "disabled"
      assert result =~ "There are no earlier trips"
    end
  end

  describe "later_link/1" do
    test "shows a link to update the offset parameter" do
      result = build_link(3, &later_link/1)

      assert result =~ "Show later times"
      refute result =~ "disabled"
    end

    test "disables the link if the current offset is greater than the number of schedules minus num_schedules()" do
      result = build_link(7, &later_link/1)
      assert result =~ "disabled"
      assert result =~ "There are no later trips"
    end
  end
end
