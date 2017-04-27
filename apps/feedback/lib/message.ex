defmodule Feedback.Message do
  @moduledoc """
  Information for a customer support message.
  """
  defstruct [:email, :phone, :name, :comments, :request_response, :photo]
end
