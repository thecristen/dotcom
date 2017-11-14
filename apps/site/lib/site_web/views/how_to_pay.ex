defmodule SiteWeb.HowToPayView do
  use SiteWeb, :view

  import SiteWeb.ViewHelpers

  @spec mode_template(atom) :: String.t
  def mode_template(mode) do
    "#{mode}.html"
  end
end
