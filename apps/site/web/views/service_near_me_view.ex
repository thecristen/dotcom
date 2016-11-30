defmodule Site.ServiceNearMeView do
  use Site.Web, :view

  def get_type_list(type, routes) when type in [:commuter, :bus, :ferry] do
    "<strong>#{mode_name(type)}</strong>: #{route_name_list(routes)}" |> Phoenix.HTML.raw
  end

  def get_type_list(type, _) do
    "#{mode_name(type)}"
  end

  def route_name_list(routes) do
    routes
    |> Enum.map(&(&1.name))
    |> Enum.join(", ")
  end
end
