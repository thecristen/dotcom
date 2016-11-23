defmodule Site.HowToPayView do
  use Site.Web, :view

  import Site.ViewHelpers

  @spec mode_template(atom) :: String.t
  def mode_template(mode) do
    "#{mode}.html"
  end

  @spec mode_string(atom) :: String.t
  def mode_string(:the_ride), do: "the-ride"
  def mode_string(:commuter_rail), do: "commuter-rail"
  def mode_string(mode), do: "#{mode}"
end
