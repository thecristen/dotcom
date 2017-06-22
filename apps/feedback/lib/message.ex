defmodule Feedback.Message do
  @moduledoc """
  Information for a customer support message.
  """
  defstruct [:email, :phone, :name, :comments, :request_response, :photos]
  @type t :: %__MODULE__{
    email: String.t | nil,
    phone: String.t | nil,
    name: String.t | nil,
    comments: String.t,
    request_response: boolean,
    photos: [Plug.Upload.t] | nil
  }
end
