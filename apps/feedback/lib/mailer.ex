defmodule Feedback.Mailer do
  use Mailgun.Client

  # Mix isn't available at runtime
  @mix_env Mix.env

  def config do
    [domain: Application.get_env(:feedback, :mailgun_domain),
     key: Application.get_env(:feedback, :mailgun_key),
     test_file_path: Application.get_env(:feedback, :test_mail_file),
     mode: @mix_env]
  end

  def send_ticket(text, photo_info) do
    opts = [to: Application.get_env(:feedback, :support_ticket_to_email),
            from: Application.get_env(:feedback, :support_ticket_from_email),
            subject: "MBTA Customer Comment Form",
            text: text]

    opts = if photo_info do
      [{:attachments, [photo_info]} | opts]
    else
      opts
    end

    Mailgun.Client.send_email config(), opts
  end
end
