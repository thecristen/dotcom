defmodule Site.Components.Icons.SvgIconWithCircle do
  defstruct icon: :bus,
            small: false

  def translate(:globe), do: "5,5"
  def translate(:suitcase), do: "8,10"
  def translate(:t_logo), do: "7,10"
  def translate(:phone), do: "11,8"
  def translate(:map), do: "7,8"
  def translate(:accessible), do: "8,6"
  def translate(:green_line), do: translate(:t_logo)
  def translate(:orange_line), do: translate(:t_logo)
  def translate(:blue_line), do: translate(:t_logo)
  def translate(:red_line), do: translate(:t_logo)
  def translate(:mattapan_line), do: translate(:t_logo)
  def translate(icon) when icon in [:phone, :tools, :ferry, :alert], do: "8,8"
  def translate(icon) when icon in [:bus, :subway, :commuter], do: "10,8"
  def translate(_), do: "4,4"
end
