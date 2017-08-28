defmodule Content.ImageHelpers do
  def site_app_domain do
    "#{site_app_host()}:#{site_app_port()}"
  end

  defp site_app_host do
    {:url, [host: host]} = List.keyfind(site_app_config(), :url, 0)
    host
  end

  defp site_app_port do
    {:http, [port: port]} = List.keyfind(site_app_config(), :http, 0)
    port
  end

  defp site_app_config do
    Application.get_env(:site, Site.Endpoint)
  end
end
