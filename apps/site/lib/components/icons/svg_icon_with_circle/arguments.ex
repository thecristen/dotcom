defmodule Site.Components.Icons.SvgIconWithCircle do
  defstruct icon:  :bus,
            class: ""
  @type t :: %__MODULE__{
    icon: Site.Components.Icons.SvgIcon.icon_arg,
    class: String.t
  }

  def circle_viewbox(:twitter), do: "400 400"
  def circle_viewbox(:facebook), do: "75 75"
  def circle_viewbox(_icon), do: "42 42"

  def translate(:globe), do: "6,6"
  def translate(:suitcase), do: "9,11"
  def translate(:t_logo), do: "8,11"
  def translate(:map), do: "8,9"
  def translate(:access), do: "9,7"
  def translate(:twitter), do: "5,10"
  def translate(:facebook), do: "8,8"
  def translate(icon) when icon in [:phone, :subway], do: "12,9"
  def translate(icon) when icon in [:tools, :ferry, :alert], do: "9,9"
  def translate(icon) when icon in [:bus, :commuter_rail], do: "11,9"
  def translate(icon) when icon in [:green_line, :orange_line,
                                    :blue_line, :red_line, :mattapan_line], do: translate(:t_logo)
  def translate(_), do: "5,5"

  def circle_args(:twitter), do: "r=200 cx=200 cy=200"
  def circle_args(:facebook), do: "r=37 cx=37 cy=37"
  def circle_args(_icon), do: "r=20 cx=20 cy=20"

  def title(icon) when icon in [
    :bus, :subway, :ferry, :commuter_rail, :the_ride, :access,
    :orange_line, :green_line, :red_line, :blue_line, :mattapan_line
  ] do
    Site.ViewHelpers.mode_name(icon)
  end
  def title(%Routes.Route{id: "Orange"}), do: Site.ViewHelpers.mode_name(:orange_line)
  def title(%Routes.Route{id: "Red"}), do: Site.ViewHelpers.mode_name(:red_line)
  def title(%Routes.Route{id: "Blue"}), do: Site.ViewHelpers.mode_name(:blue_line)
  def title(%Routes.Route{id: "Mattapan"}), do: Site.ViewHelpers.mode_name(:mattapan_line)
  def title(%Routes.Route{id: "Green" <> _}), do: Site.ViewHelpers.mode_name(:green_line)
  def title(_icon), do: ""
end
