defmodule Content.Api do
  @moduledoc """
  The behaviour for a live HTTP or a static testing API over our content CMS.
  """

  @doc """
  Issues a request for a given path, with optional parameters
  for the request. Parses the JSON result but does not do anything
  beyond that. Shouldn't raise an exception; if the HTTP request
  or JSON decoding fails, returns {:error, message}
  """
  @callback view(String.t, Keyword.t) :: {:ok, list(map())} | {:ok, map()} | {:error, any}
end
