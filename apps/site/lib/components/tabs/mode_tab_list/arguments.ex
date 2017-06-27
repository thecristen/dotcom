defmodule Site.Components.Tabs.ModeTabList do
  @moduledoc """
  Renders a list of tabs for transport modes, as well as The Ride and accessibility.
  
  By default the tab is shown with each button using the same width. 
  Use class=tab-select-btn-group-table-layout-auto to make the button widths adjust to the text inside them.
  """
  alias Site.ViewHelpers

  defstruct [
    id: "modes",
    class: "",
    links: for mode <- [:bus, :commuter_rail, :subway, :ferry] do
             {mode, Site.Router.Helpers.schedule_path(Site.Endpoint, :show, mode)}
           end,
    selected_mode: :bus
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [{mode_atom:: atom, href:: String.t}],
    selected_mode: atom
  }

  def mode_links(links) do
    Enum.map(links, fn {mode_atom, href} -> {Atom.to_string(mode_atom), ViewHelpers.mode_name(mode_atom), href} end)
  end

  def build_mode_icon_map(links) do
    Map.new(modes(links), &do_build_mode_icon_map/1)
  end

  defp do_build_mode_icon_map(mode) do
    icon = Site.PageView.svg_icon_with_circle(%Site.Components.Icons.SvgIconWithCircle{icon: mode, aria_hidden?: true})
    {ViewHelpers.mode_name(mode), icon}
  end

  defp modes(links) do
    Enum.map(links, fn {mode, _} -> mode end)
  end
end
