defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  @impl true
  def preview(node_id) do
    path = ~s(/api/revisions/#{node_id})
    Content.ExternalRequest.process(:get, path, "", [
      params: [_format: "json"],
      # More time needed (receives 1 - 50 JSON node entities)
      timeout: 30_000,
      recv_timeout: 30_000
    ])
  end

  @impl true
  def view(path, params) do
    params = [{"_format", "json"} | Enum.map(params, fn {key, val} -> {to_string(key), val} end)]

    Content.ExternalRequest.process(:get, path, "", [
      params: params
    ])
  end

  @impl true
  def post(path, body) do
    Content.ExternalRequest.process(:post, path, body)
  end

  @impl true
  def update(path, body) do
    Content.ExternalRequest.process(:patch, path, body)
  end
end
