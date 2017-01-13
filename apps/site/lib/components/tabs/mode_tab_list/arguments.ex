defmodule Site.Components.Tabs.ModeTabList do
  @moduledoc """
  Renders a list of tabs for transport modes, as well as The Ride and accessibility. Can optionally collapse
  at xs or sm breakpoints.
  """

  defstruct [
    id: "modes",
    class: "",
    links: for mode <- [:bus, :commuter_rail, :subway, :ferry] do
             {mode, Site.Router.Helpers.schedule_path(Site.Endpoint, :show, mode)}
           end,
    selected_mode: :bus,
    collapse: nil
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [{atom, String.t}],
    selected_mode: atom,
    collapse: String.t | nil
  }

  def selected?(mode, mode), do: true
  def selected?(_, _), do: false

  def btn_class("xs"), do: "hidden-sm-up"
  def btn_class("sm"), do: "hidden-md-up"
  def btn_class(_collapse), do: ""

  def nav_class("xs"), do: "collapse navbar-toggleable-xs"
  def nav_class("sm"), do: "collapse navbar-toggleable-sm"
  def nav_class(_collapse), do: ""
end
