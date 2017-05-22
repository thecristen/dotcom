defmodule Feedback.Repo do

  @spec send_ticket(Feedback.Message.t) :: {:ok, any} | {:error, any}
  def send_ticket(message) do
    message
    |> Feedback.Mailer.send_heat_ticket(photo_attachment(message.photo))
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
