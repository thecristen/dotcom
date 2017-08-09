defmodule Feedback.Message do
  @moduledoc """
  Information for a customer support message.
  """

  @service_options [
    {"Complaint", "Complaint"},
    {"Comment", "Suggestion"},
    {"Question", "Inquiry"},
    {"Request", "Inquiry"}
  ]

  @enforce_keys [:comments, :service, :request_response]
  defstruct [:email, :phone, :name, :comments, :service, :request_response, :photos]
  @type t :: %__MODULE__{
    email: String.t | nil,
    phone: String.t | nil,
    name: String.t | nil,
    comments: String.t,
    service: String.t,
    request_response: boolean,
    photos: [Plug.Upload.t] | nil
  }

  def service_options do
    @service_options
  end

  def valid_service?(value) do
    value in Enum.map(service_options(), &elem(&1, 1))
  end
end
