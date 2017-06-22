defmodule Feedback.Repo do

  @spec send_ticket(Feedback.Message.t) :: {:ok, any} | {:error, any}
  def send_ticket(message) do
    message
    |> Feedback.Mailer.send_heat_ticket(photo_attachment(message.photos))
  end

  def photo_attachment([%Plug.Upload{} | _rest] = photos) do
    Enum.map(photos, fn %Plug.Upload{path: path, filename: filename} ->
      %{path: path, filename: filename}
    end)
  end
  def photo_attachment(nil), do: nil
end
