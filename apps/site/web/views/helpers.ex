defmodule Site.ViewHelpers do
  import Site.Router.Helpers
  import Phoenix.HTML, only: [raw: 1]
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  def svg(path) do
    :site
    |> Application.app_dir
    |> Path.join("priv/static" <> path)
    |> File.read!
    |> String.split("\n")
    |> Enum.join("")
    |> raw
  end
  def svg(_conn, path) do
    # TODO remove old uses of svg/2
    svg(path)
  end

  def redirect_path(conn, path) do
    redirect_path(conn, :show, path)
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
  def mode_name(0), do: mode_name(1)
  def mode_name(1), do: "Subway"
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
end
