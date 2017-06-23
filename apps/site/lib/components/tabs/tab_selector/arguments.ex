defmodule Site.Components.Tabs.TabSelector do
  @moduledoc """
  Component for tab selection.
  """

  defstruct [
    id: "tab-select",
    class: "",
    links: [
      {"trip-view", "Schedule", Site.Router.Helpers.schedule_path(Site.Endpoint, :show, :bus)},
      {"info", "Info", Site.Router.Helpers.line_path(Site.Endpoint, :show, :bus)}],
    selected: "trip-view",
    icon_map: %{},
  ]

  @type t :: %__MODULE__{
    id: String.t,
    class: String.t,
    links: [%{tab_item_name: String.t, title: String.t, href: String.t, icon: Phoenix.HTML.safe | nil, selected?: boolean}],
  }

  def selected?(tab_item_name, tab_item_name), do: true
  def selected?(_, _), do: false

  @spec slug(String.t) :: String.t
  def slug(title) do
    String.replace(String.downcase(title), " ", "-") <> "-tab"
  end
end
