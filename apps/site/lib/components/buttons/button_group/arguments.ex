defmodule Site.Components.Buttons.ButtonGroup do
  @moduledoc """
  Convenience function for rendering a formatted list of links. Links should be passed as
  a list of [{text, href}]. The link text can either be a string, or a list of child elements
  like what would be passed to Phoenix.HTML.Link.

  To set the width the links at each breakpoint, pass a :breakpoint_widths map
  as an argument. This should be a map of {breakpoint_name, columns} for each
  breakpoint you want to set. Defaults to %{xs: 12, sm: 6, md: 4, xxl: 3}
  """
  defstruct class:   "",
            id:      nil,
            breakpoint_widths: %{
              xs: 12,
              sm: 6,
              md: 4,
              xxl: 3
            },
            links:   [
              {"Sample link 1", Site.Router.Helpers.page_path(Site.Endpoint, :index)},
              {"Sample link 2", Site.Router.Helpers.page_path(Site.Endpoint, :index)}
            ]

  @type t :: %__MODULE__{
    class: String.t,
    id: String.t | nil,
    breakpoint_widths: %{xs: integer, sm: integer, md: integer, xxl: integer},
    links: [button_arguments]
  }

  @type button_arguments :: {button_content, String.t}
  @type button_content :: String.t | [String.t | Phoenix.HTML.Safe.t]

  @doc "Returns a string with column width classes (\"col-xs-12\", \"col-md-6\", etc)."
  @spec breakpoint_widths(__MODULE__.t) :: String.t
  def breakpoint_widths(%__MODULE__{breakpoint_widths: breakpoints}) do
    %__MODULE__{}
    |> Map.get(:breakpoint_widths)
    |> Map.merge(breakpoints)
    |> Enum.reduce("", &do_breakpoint_width/2)
    |> String.trim
  end

  @spec do_breakpoint_width({atom, integer}, String.t) :: String.t
  defp do_breakpoint_width({breakpoint, columns}, acc) do
    acc <> " col-#{breakpoint}-#{columns}"
  end
end
