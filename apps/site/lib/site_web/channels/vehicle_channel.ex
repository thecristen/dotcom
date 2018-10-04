defmodule SiteWeb.VehicleChannel do
  use SiteWeb, :channel

  def join("vehicles:" <> _params, %{}, socket) do
    {:ok, socket}
  end
end
