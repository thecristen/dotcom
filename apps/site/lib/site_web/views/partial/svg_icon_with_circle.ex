defmodule SiteWeb.PartialView.SvgIconWithCircle do

  defstruct icon:  :bus,
            class: "",
            show_tooltip?: true,
            aria_hidden?: false

  @type t :: %__MODULE__{
    icon: Site.Components.Icons.SvgIcon.icon_arg,
    class: String.t,
    show_tooltip?: boolean,
    aria_hidden?: boolean
  }

  def svg_icon_with_circle(%__MODULE__{} = args) do
    icon = Site.Components.Icons.SvgIcon.get_icon_atom(args.icon)
    data_toggle = if args.show_tooltip?, do: "data-toggle=tooltip", else: ""
    title = if args.show_tooltip?, do: title(icon), else: ""
    Phoenix.View.render(SiteWeb.PartialView, "_icon_with_circle.html", [
      icon: icon,
      data_toggle: data_toggle,
      title: title,
      aria_hidden?: args.aria_hidden?,
      class: args.class,
      circle_viewbox: circle_viewbox(icon),
      circle_args: circle_args(icon),
      translate: translate(icon),
      scale: scale(icon),
      rotate: rotate(icon),
      path: Site.Components.Icons.SvgIcon.get_path(icon),
      hyphenated_class: "icon-#{CSSHelpers.atom_to_class(icon)}"
    ])
  end

  def circle_viewbox(:twitter), do: "0 0 400 400"
  def circle_viewbox(:facebook), do: "0 0 75 75"
  def circle_viewbox(_icon), do: "0 0 42 42"

  def translate(:globe), do: "6,6"
  def translate(:suitcase), do: "9,11"
  def translate(:map), do: "8,9"
  def translate(:fare_ticket), do: "3,13"
  def translate(:access), do: "9,7"
  def translate(:twitter), do: "5,10"
  def translate(:facebook), do: "8,8"
  def translate(:nineoneone), do: "9,9"
  def translate(:phone), do: "12,9"
  def translate(:calendar), do: "6,5"
  def translate(:direction), do: "6,5"
  def translate(:variation), do: "12,11"
  def translate(:station), do: "4,4"
  def translate(:stop), do: "4,4"
  def translate(icon) when icon in [:tools, :alert], do: "9,9"
  def translate(icon) do
    cond do
      icon in Site.Components.Icons.SvgIcon.mode_icons() -> "10,10"
      icon in Site.Components.Icons.SvgIcon.transit_type_icons() -> "4,4"
      true -> "5,5"
    end
  end

  def scale(:nineoneone), do: ".25"
  def scale(:fare_ticket), do: "1.6"
  def scale(:direction), do: "1.25"
  def scale(:variation), do: "1.25"
  def scale(:calendar), do: "1.25"
  def scale(:station), do: "0.7"
  def scale(:stop), do: "0.7"
  def scale(icon) do
    cond do
      icon in Site.Components.Icons.SvgIcon.mode_icons() -> "1.4"
      icon in Site.Components.Icons.SvgIcon.transit_type_icons() -> "0.7"
      true -> "1"
    end
  end

  def rotate(:fare_ticket), do: "rotate(-15)"
  def rotate(_), do: ""

  def circle_args(:twitter), do: "r=200 cx=200 cy=200"
  def circle_args(:facebook), do: "r=37 cx=37 cy=37"
  def circle_args(_icon), do: "r=20 cx=20 cy=20"

  def title(:access) do
    "Accessible"
  end
  def title(icon) when icon in [
    :bus, :subway, :ferry, :commuter_rail, :the_ride,
    :orange_line, :green_line, :red_line, :blue_line,
    :mattapan_trolley, :mattapan_line
  ] do
    SiteWeb.ViewHelpers.mode_name(icon)
  end
  def title(%Routes.Route{id: "Orange"}), do: SiteWeb.ViewHelpers.mode_name(:orange_line)
  def title(%Routes.Route{id: "Red"}), do: SiteWeb.ViewHelpers.mode_name(:red_line)
  def title(%Routes.Route{id: "Blue"}), do: SiteWeb.ViewHelpers.mode_name(:blue_line)
  def title(%Routes.Route{id: "Mattapan"}), do: SiteWeb.ViewHelpers.mode_name(:mattapan_line)
  def title(%Routes.Route{id: "Green" <> _}), do: SiteWeb.ViewHelpers.mode_name(:green_line)
  def title(%Routes.Route{type: type}), do: SiteWeb.ViewHelpers.mode_name(type)
  def title(_icon), do: ""
end
