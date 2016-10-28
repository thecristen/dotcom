defmodule Site.HowToPayView do
  use Site.Web, :view

  import Site.ViewHelpers

  @spec mode_template(atom) :: String.t
  def mode_template(mode) do
    "#{mode}.html"
  end

  @spec mode_string(atom) :: String.t
  def mode_string(:the_ride) do
    "the-ride"
  end
  def mode_string(mode) do
    "#{mode}"
  end

  @spec mode_title(atom) :: String.t
  def mode_title(:the_ride) do
    "The RIDE"
  end
  def mode_title(mode) do
    String.capitalize("#{mode}")
  end
end
