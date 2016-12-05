defmodule Site.Components.Icons.SvgIconWithCircle do
  defstruct icon:  :bus,
            class: ""
  @type t :: %__MODULE__{
    icon: atom,
    class: String.t
  }

  def translate(:globe), do: "6,6"
  def translate(:suitcase), do: "9,11"
  def translate(:t_logo), do: "8,11"
  def translate(:map), do: "8,9"
  def translate(:access), do: "9,7"
  def translate(icon) when icon in [:phone, :subway], do: "12,9"
  def translate(icon) when icon in [:tools, :ferry, :alert], do: "9,9"
  def translate(icon) when icon in [:bus, :commuter_rail], do: "11,9"
  def translate(icon) when icon in [:green_line, :orange_line,
                                    :blue_line, :red_line, :mattapan_line], do: translate(:t_logo)
  def translate(_), do: "5,5"
end
