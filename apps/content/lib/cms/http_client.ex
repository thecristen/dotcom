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
      | Enum.reduce(params, [], &stringify_params/2)
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

  @spec stringify_params({String.t() | atom, String.t() | atom}, [{String.t(), String.t()}]) :: [
          {String.t(), String.t()}
        ]
  defp stringify_params({key, val}, acc) when is_atom(key) do
    stringify_params({Atom.to_string(key), val}, acc)
  end

  defp stringify_params({key, val}, acc) when is_atom(val) do
    stringify_params({key, Atom.to_string(val)}, acc)
  end

  defp stringify_params({key, val}, acc) when is_integer(val) do
    stringify_params({key, Integer.to_string(val)}, acc)
  end

  defp stringify_params({key, val}, acc) when is_binary(key) and is_binary(val) do
    [{key, val} | acc]
  end

  defp stringify_params(_, acc) do
    # drop invalid param
    acc
  end
end
