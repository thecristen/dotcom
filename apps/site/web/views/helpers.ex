defmodule Site.ViewHelpers do
  import Site.Router.Helpers
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Link
  import Util

  def svg(path) do
    :site
    |> Application.app_dir
    |> Path.join("priv/static" <> path)
    |> File.read!
    |> String.split("\n")
    |> Enum.join("")
    |> raw
  end

  def redirect_path(conn, path) do
    redirect_path(conn, :show, path)
  end

  def google_tag_manager_id do
    case env(:google_tag_manager_id) do
      "" -> nil
      id -> id
    end
  end

  def google_api_key do
    env(:google_api_key)
  end

  def font_awesome_id do
    env(:font_awesome_id)
  end

  defp env(key) do
    Application.get_env(:site, __MODULE__)[key]
  end

  @doc "HTML for a FontAwesome icon"
  def fa(name) do
    class_name = "fa fa-#{name}"
    raw ~s(<i class="#{class_name}" aria-hidden=true></i>)
  end

  @doc "The string description of a direction ID"
  def direction(direction_id, route_id)
  def direction(0, "Red"), do: "Southbound"
  def direction(1, "Red"), do: "Northbound"
  def direction(0, "Orange"), do: "Southbound"
  def direction(1, "Orange"), do: "Northbound"
  def direction(0, "Blue"), do: "Westbound"
  def direction(1, "Blue"), do: "Eastbound"
  def direction(0, "Green" <> _), do: "Westbound"
  def direction(1, "Green" <> _), do: "Eastbound"
  def direction(0, _), do: "Outbound"
  def direction(1, _), do: "Inbound"
  def direction(_, _), do: "Unknown"

  @doc "HTML for an icon representing a mode"
  def mode_icon(type)
  def mode_icon(0), do: mode_icon(1)
  def mode_icon(1), do: do_mode_icon("subway")
  def mode_icon(2), do: do_mode_icon("commuter-rail", "commuter")
  def mode_icon(3), do: do_mode_icon("bus")
  def mode_icon(4), do: do_mode_icon("boat")

  defp do_mode_icon(name, svg_name \\ nil) do
    svg_name = svg_name || name
    content_tag :span, class: "route-icon route-icon-#{name}" do
      svg("/images/#{svg_name}.svg")
    end
  end

  @doc "Textual version of a mode ID"
  def mode_name(type)
  def mode_name(type) when type in [0, 1], do: "Subway"
  def mode_name(2), do: "Commuter Rail"
  def mode_name(3), do: "Bus"
  def mode_name(4), do: "Boat"

  @doc "Clean up a GTFS route name for better presentation"
  def clean_route_name(name) do
    name
    |> String.replace_suffix(" Line", "")
    |> String.replace("/", "/​") # slash replaced with a slash with a ZERO
                                # WIDTH SPACE afer
  end

  @doc "HTML for a route icon"
  def route_icon(route_type, route_id)
  def route_icon(route_type, route_id) when route_type in [0, 1] do
    fa("circle fa-color-subway-" <> String.downcase(route_id))
  end
  def route_icon(_,_), do: raw ""

  @doc "HTML for a Route link"
  def route_link(conn, route) do
    link(raw(string_join(safe_to_string(route_icon(route.type, route.id)), clean_route_name(route.name))),
          to: schedule_path(conn, :index, route: route.id), 
          class: "mode-group-btn")
  end

  def route_spacing_class(1), do: "col-xs-6 col-md-3"
  def route_spacing_class(2), do: "col-xs-6 col-md-3"
  def route_spacing_class(3), do: "col-xs-4 col-md-2"
  def route_spacing_class(4), do: "col-xs-12 col-md-4"
end
