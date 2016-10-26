defmodule Site.HowToPayView do
  use Site.Web, :view

  import Site.ViewHelpers

  def mode_template(mode) do
    "#{mode}.html"
  end

  def mode_string(:the_ride) do
    "the-ride"
  end
  def mode_string(mode) do
    "#{mode}"
  end
end
