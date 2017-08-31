defmodule Site.PartialView do
  use Site.Web, :view
  alias Plug.Conn
  import Site.ContentView, only: [file_description: 1]
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
  @spec stop_selector_suffix(Conn.t, Stops.Stop.id_t) :: iodata
  def stop_selector_suffix(%Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, stop_id) do
    if zone = conn.assigns.zone_map[stop_id] do
      ["Zone ", zone]
    else
      ""
    end
  end
  def stop_selector_suffix(%Conn{assigns: %{route: %Routes.Route{id: "Green"}}} = conn, stop_id) do
    GreenLine.branch_ids()
    |> Enum.flat_map(fn route_id ->
      if GreenLine.stop_on_route?(stop_id, route_id, conn.assigns.stops_on_routes) do
        [display_branch_name(route_id)]
      else
        []
      end
    end)
    |> Enum.join(",")
  end
  def stop_selector_suffix(_conn, _stop_id) do
    ""
  end

  @doc """
  Pulls out the branch name of a Green Line route ID.
  """
  @spec display_branch_name(Routes.Route.id_t) :: String.t | nil
  def display_branch_name(<<"Green-", branch :: binary>>), do: branch
  def display_branch_name(_), do: nil

end
