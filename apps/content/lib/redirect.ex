defmodule Content.Redirect do
  @moduledoc """

  Represents the "Redirect" content type in the CMS. If there is a redirect, the user should get redirected to
  the specified url.

  """

  import Content.Helpers, only: [parse_link_type: 2]

  defstruct [url: ""]

  @type t :: %__MODULE__{
    url: String.t
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      url: parse_link_type(data, "field_redirect_to")
    }
  end
end
