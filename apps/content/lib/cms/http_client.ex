defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.ExternalRequest, only: [process: 3, process: 4]

  def view(path, params \\ []) do
    params = Keyword.merge(params, [_format: "json"])
    process(:get, path, "", params)
  end

  def post(path, body) do
    process(:post, path, body)
  end

  def update(path, body) do
    process(:patch, path, body)
  end
end
