defmodule Content.Router do
  @moduledoc """

  A Router to use for handling content coming from our CMS.
  """
  use Phoenix.Router

  get "/sites/*path", Content.Controller, :static_file
  get "/*path", Content.Controller, :show
end
