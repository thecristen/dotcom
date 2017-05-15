defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.ExternalRequest, only: [process: 3, process: 4]

  @spec view(String.t, Keyword.t) :: {:ok, Poison.Parser.t} | {:error, map} | {:error, String.t}
  def view(path, params \\ []) do
    params = Keyword.merge(params, [_format: "json"])
    process(:get, path, "", params)
  end

  @spec post(String.t, String.t) :: {:ok, Poison.Parser.t} | {:error, map} | {:error, String.t}
  def post(path, body) do
    process(:post, path, body)
  end

  @spec update(String.t, String.t) :: {:ok, Poison.Parser.t} | {:error, map} | {:error, String.t}
  def update(path, body) do
    process(:patch, path, body)
  end
end
