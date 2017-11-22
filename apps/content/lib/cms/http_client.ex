defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.ExternalRequest, only: [process: 3, process: 4]

  @spec view_or_preview(String.t, Keyword.t) :: {:ok, map()} | {:error, String.t}
  def view_or_preview(path, params) do
    raw_result = with [preview: _, vid: revision_id] <- params,
         ["", "node", node_id] <- String.split(path, "/"),
         {_, ""} <- Integer.parse(node_id),
         {_, ""} <- Integer.parse(revision_id)
    do
      preview(params, node_id, revision_id)
    else
      _ -> view(path, params)
    end
    case raw_result do
      {:ok, []} -> {:error, "No results"}
      {:ok, [first | _]} -> {:ok, first}
      e -> e
    end
  end

  @spec preview(Keyword.t, String.t, String.t) :: {:ok, list(map())} | {:ok, map()} | {:error, String.t}
  def preview(params, node_id, revision_id) do
    path = ~s(/api/node/#{node_id}/revision/#{revision_id})
    process(:get, path, "", params)
  end

  @impl true
  def view(path, params) do
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
