defmodule Site.Components.Tabs.ModeTabList do
  @moduledoc """
  Renders a list of tabs for transport modes, as well as The Ride and accessibility. Can optionally collapse
  at xs or sm breakpoints.
  """
  alias Site.ViewHelpers

  defstruct [
    id: "modes",
    class: "",
    links: for mode <- [:bus, :commuter_rail, :subway, :ferry] do
             {mode, Site.Router.Helpers.schedule_path(Site.Endpoint, :show, mode)}
           end,
    selected_mode: :bus,
    collapse: "xs"
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [{atom, String.t}],
    selected_mode: atom,
    collapse: String.t | nil
  }

  def mode_links(links) do
    Enum.map(links, fn {mode_atom, href} -> {ViewHelpers.mode_name(mode_atom), href} end)
  end

  def build_mode_icon_map(links) do
    Map.new(modes(links), &do_build_mode_icon_map/1)
  end

  defp do_build_mode_icon_map(mode) do
    icon = Site.PageView.svg_icon_with_circle(%Site.Components.Icons.SvgIconWithCircle{icon: mode})
    {ViewHelpers.mode_name(mode), icon}
  end

  defp modes(links) do
    Enum.map(links, fn {mode, _} -> mode end)
  end
end
