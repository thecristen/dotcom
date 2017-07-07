defmodule Site.ScheduleV2View.StopList do
  use Site.Web, :view

  alias Site.ScheduleV2Controller.Line, as: LineController
  alias Stops.{RouteStop, RouteStops}

  @doc """
  Determines whether a stop is the first stop of its branch that is shown on the page, and
  therefore should display a link to expand/collapse the branch.
  """
  @spec add_expand_link?(RouteStop.t, map) :: boolean
  def add_expand_link?(%RouteStop{branch: nil}, _assigns), do: false
  def add_expand_link?(_, %{route: %Routes.Route{id: "CR-Kingson"}}), do: false
  def add_expand_link?(%RouteStop{branch: "Green-" <> _ = branch} = stop, assigns) do
    case assigns do
      %{expanded: ^branch, direction_id: 0} -> GreenLine.split_id(branch) == stop.id
      _ -> GreenLine.terminus?(stop.id, branch)
    end
  end
  def add_expand_link?(%RouteStop{id: stop_id, branch: branch}, assigns) do
    case Enum.find(assigns.branches, & &1.branch == branch) do
      %RouteStops{stops: [_]} -> true
      %RouteStops{stops: [%RouteStop{id: ^stop_id}|_]} -> true
      _ -> false
    end
  end

  @doc """
  Link to expand or collapse a route branch.
  """
  @spec view_branch_link(Plug.Conn.t, String.t | nil, String.t) :: Phoenix.HTML.Safe.t
  def view_branch_link(conn, "Green-" <> letter, "Green-" <> letter) do
    do_branch_link(conn, nil, letter, :hide)
  end
  def view_branch_link(conn, _, "Green-" <> letter) do
    do_branch_link(conn, "Green-" <> letter, letter, :view)
  end
  def view_branch_link(conn, branch_name, branch_name) do
    do_branch_link(conn, nil, branch_name, :hide)
  end
  def view_branch_link(conn, _, branch_name) do
    do_branch_link(conn, branch_name, branch_name, :view)
  end

  @spec do_branch_link(Plug.Conn.t, String.t | nil, String.t, :hide | :view) :: Phoenix.HTML.Safe.t
  defp do_branch_link(conn, expanded, branch_name, action) do
    {action_text, caret} = case action do
                             :hide -> {"Hide ", "up"}
                             :view -> {"View ", "down"}
                           end
    link to: update_url(conn, expanded: expanded), class: "branch-link" do
      [content_tag(:span, action_text, class: "hidden-sm-down"), branch_name, " Branch ", fa("caret-#{caret}")]
    end
  end

  @doc """
  Sets the direction_id for the "Schedules from here" link. Chooses the opposite of the current direction only for the last stop
  on the line or branch (since there are no trips in that direction from those stops).
  """
  @spec schedule_link_direction_id(RouteStop.t, [{LineController.stop_bubble_type, String.t}], 0 | 1) :: 0 | 1
  def schedule_link_direction_id(%RouteStop{is_terminus?: true, stop_number: number}, _, direction_id) when number != 0 do
    case direction_id do
      0 -> 1
      1 -> 0
    end
  end
  def schedule_link_direction_id(_, _, direction_id), do: direction_id
end
