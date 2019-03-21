defmodule SiteWeb.ContentHelpers do
  @moduledoc """
  Various helper functions that aid in rendering CMS content.
  """

  import SiteWeb.ViewHelpers, only: [route_to_class: 1]

  alias Routes.Repo

  @doc "Returns the text if present, otherwise returns nil"
  @spec content(String.t()) :: String.t() | nil
  @spec content(Phoenix.HTML.safe()) :: Phoenix.HTML.safe() | nil
  def content(nil) do
    nil
  end

  def content({:safe, string} = safe_html) do
    if content(string) do
      safe_html
    end
  end

  def content(string) do
    case String.trim(string) do
      "" -> nil
      string -> string
    end
  end

  @doc """
  Converts CMS-flavored routes to classes, where the route may
  not strictly be an ID that matches an elixir route ID.

  Example: authors can tag something with an umbrella term like
  "commuter_rail" or "silver_line" to indicate the content item
  is related to all routes on that mode or line.
  """
  @spec cms_route_to_class(map()) :: String.t()
  def cms_route_to_class(%{id: "silver_line"}), do: "silver-line"
  def cms_route_to_class(%{id: "mattapan"}), do: "red-line"
  def cms_route_to_class(%{group: "custom", mode: mode}), do: String.replace(mode, "_", "-")
  def cms_route_to_class(%{group: "mode", id: mode}), do: String.replace(mode, "_", "-")
  def cms_route_to_class(%{id: id}), do: id |> Repo.get() |> route_to_class()
end
