defmodule Content.CMS.HTTPClient do
  @moduledoc """

  Performs composition of external requests to CMS API.

  """

  alias Content.ExternalRequest

  @behaviour Content.CMS

  @impl true
  def preview(node_id, revision_id) do
    path = ~s(/cms/revisions/#{node_id})

    ExternalRequest.process(
      :get,
      path,
      "",
      params: [_format: "json", vid: revision_id],
      # More time needed to lookup revision (CMS filters through ~50 revisions)
      timeout: 10_000,
      recv_timeout: 10_000
    )
  end

  @impl true
  def view(path, params) do
    params = [
      {"_format", "json"}
      | Enum.map(params, fn {key, val} -> {to_string(key), to_string(val)} end)
    ]

    ExternalRequest.process(:get, path, "", params: params)
  end

  @impl true
  def post(path, body) do
    ExternalRequest.process(:post, path, body)
  end

  @impl true
  def update(path, body) do
    ExternalRequest.process(:patch, path, body)
  end
end
