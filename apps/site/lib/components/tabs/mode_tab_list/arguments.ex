defmodule Site.Components.Tabs.ModeTabList do
  @moduledoc """
  Renders a list of tabs for transport modes, as well as The Ride and accessibility. By default, collapses
  at the smallest breakpoint with a button to expand.
  """

  defstruct [
    id: "modes",
    class: "navbar-toggleable-xs m-y-1",
    links: for mode <- [:bus, :commuter_rail, :subway, :ferry] do
             {mode, Site.Router.Helpers.schedule_path(Site.Endpoint, :show, mode)}
           end,
    selected_mode: :bus,
    btn_class: "hidden-sm-up"
  ]

  def selected?(mode, mode), do: true
  def selected?(_, _), do: false
end
