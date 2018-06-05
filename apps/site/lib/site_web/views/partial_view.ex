defmodule SiteWeb.PartialView do
  use SiteWeb, :view
  alias Plug.Conn
  alias SiteWeb.PartialView.SvgIconWithCircle
  import SiteWeb.ContentView, only: [file_description: 1]
  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  @spec clear_selector_link(map()) :: Phoenix.HTML.Safe.t
  def clear_selector_link(%{clearable?: true, selected: selected} = assigns)
  when not is_nil(selected) do
    link to: update_url(assigns.conn, [{assigns.query_key, nil}]) do
      [
        "(clear",
        content_tag(:span, [" ", assigns.placeholder_text], class: "sr-only"),
        ")"
      ]
    end
  end
  def clear_selector_link(_assigns) do
    ""
  end

  @doc """
  Returns the suffix to be shown in the stop selector.
  """
  @spec stop_selector_suffix(Conn.t, Stops.Stop.id_t, String.t | nil) :: iodata
  def stop_selector_suffix(conn, stop_id, text \\ "")
  def stop_selector_suffix(%Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, stop_id, text) do
    if zone = conn.assigns.zone_map[stop_id] do
      ["Zone ", zone]
    else
      text || ""
    end
  end
  def stop_selector_suffix(%Conn{assigns: %{route: %Routes.Route{id: "Green"},
                                            stops_on_routes: stops}}, stop_id, text) do
    GreenLine.branch_ids()
    |> Enum.flat_map(& stop_id |> GreenLine.stop_on_route?(&1, stops) |> green_branch_name(&1))
    |> Enum.intersperse(",")
    |> green_line_stop_selector_suffix(text)
  end
  def stop_selector_suffix(_conn, _stop_id, text) do
    text || ""
  end

  @spec green_line_stop_selector_suffix(iodata, String.t | nil) :: String.t | iodata
  defp green_line_stop_selector_suffix([], nil), do: ""
  defp green_line_stop_selector_suffix([], <<text::binary>>), do: text
  defp green_line_stop_selector_suffix(iodata, _), do: iodata

  @spec green_branch_name(boolean, Routes.Route.id_t) :: [String.t | nil]
  defp green_branch_name(stop_on_green_line?, route_id)
  defp green_branch_name(true, route_id), do: [display_branch_name(route_id)]
  defp green_branch_name(false, _), do: []

  @doc """
  Pulls out the branch name of a Green Line route ID.
  """
  @spec display_branch_name(Routes.Route.id_t) :: String.t | nil
  def display_branch_name(<<"Green-", branch :: binary>>), do: branch
  def display_branch_name(_), do: nil
end
