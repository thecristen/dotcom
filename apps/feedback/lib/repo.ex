defmodule Feedback.Repo do

  @template """
Subject: Complaint
Mode:
Line:
Station:
Incident Date: <%= Timex.format!(Timex.now("America/New_York") |> Timex.to_date, "{0M}/{D}/{YYYY}") %>
Incident Time: <%= Timex.format!(Timex.now("America/New_York"), "{h12}:{m} {AM}") %>
Sub Topic:
Route:
Vehicle:
First Name:
Last Name:
Full Name: <%= @name %>
City:
State:
Zip Code:
EMAILID: <%= @email %>
Phone: <%= @phone %>
Additional Comments: <%= @comments %>
Sourceid: Auto Ticket 2
  """

  def send_ticket(%Feedback.Message{email: email, phone: phone, name: name, photo: photo, comments: comments} = message) do
    {:ok, _response} = @template
    |> EEx.eval_string(assigns: [email: email, phone: phone, name: name, comments: comments])
    |> Feedback.Mailer.send_ticket(photo_attachment(photo))

    message
    |> Feedback.Mailer.send_heat_ticket(photo_attachment(photo))
  end

  def photo_attachment(%Plug.Upload{path: path, filename: filename}) do
    %{path: path, filename: filename}
  end
  def photo_attachment(nil), do: nil
  def photo_attachment(data, name) do
    path = Briefly.create!
    File.write!(path, Base.decode64!(data))
    %{path: path, filename: name}
  end
end
