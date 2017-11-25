defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.ExternalRequest, only: [process: 3, process: 4]

  @impl true
  def preview(node_id) do
    path = ~s(/api/revisions/#{node_id})
    process(:get, path, "", [
      # More time needed (receives 1 - 50 JSON node entities)
      params: [],
      timeout: 30_000,
      recv_timeout: 30_000
    ])
  end

  @impl true
  def view(path, params) do
    params = Keyword.merge(params, [_format: "json"])
    process(:get, path, "", [
      params: params
    ])
  end

  @impl true
  def post(path, body) do
    process(:post, path, body)
  end

  @impl true
  def update(path, body) do
    process(:patch, path, body)
  end
end
