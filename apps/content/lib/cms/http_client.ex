defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.ExternalRequest, only: [process: 3, process: 4]

  def view_or_preview(path, params) do
    with [preview: _, vid: revision_id] <- params,
         ["", "node", node_id] <- String.split(path, "/"),
         {_, ""} <- Integer.parse(node_id),
         {_, ""} <- Integer.parse(revision_id)
    do
      preview(params, node_id, revision_id)
    else
      _ -> view(path, params)
    end
  end

  def preview(params, node_id, revision_id) do
    # IO.inspect "PREVIEW"
    path = ~s(/api/node/#{node_id}/revision/#{revision_id})
    with {:ok, [result]} <- process(:get, path, "", params) do
      {:ok, result}
    end
  end

  @impl true
  def view(path, params) do
    # IO.inspect "VIEW ONLY"
    params = Keyword.merge(params, [_format: "json"])
    process(:get, path, "", params)
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
