defmodule Site.RedirectView do
  use Site.Web, :view

  @spec redirect_url(boolean, String.t) :: String.t
  @doc "provide the correct url based on the redirect subdomain"
  def redirect_url(true, raw_path), do: raw_path
  def redirect_url(false, raw_path), do: "http://www.mbta.com/#{raw_path}"

end
