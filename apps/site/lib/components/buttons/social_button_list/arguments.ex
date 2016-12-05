defmodule Site.Components.Buttons.SocialButtonList do
  @moduledoc """

  This is a component to display some social media share icons.

  Currently: Twitter, Facebook

  """

  defstruct [
    class: nil,
    id: nil,
    url: ""
  ]
  @type t :: %__MODULE__{
    class: String.t | nil,
    id: String.t | nil,
    url: String.t
  }

  import URI, only: [encode: 1]

  @spec url(:twitter | :facebook, __MODULE__.t) :: String.t
  def url(:twitter, %__MODULE__{url: url}) do
    "https://twitter.com/home?status=#{encode(url)}"
  end
  def url(:facebook, %__MODULE__{url: url}) do
    "https://www.facebook.com/sharer/sharer.php?u=#{encode(url)}"
  end
end
