defmodule Feedback.Message do
  @moduledoc """
  Information for a customer support message.
  """
  defstruct [:email, :phone, :name, :comments, :request_response, :photo]
  @type t :: %__MODULE__{
    email: String.t | nil,
    phone: String.t | nil,
    name: String.t | nil,
    comments: String.t,
    request_response: boolean,
    photo: Plug.Upload.t | {binary, String.t} | nil
  }
end
