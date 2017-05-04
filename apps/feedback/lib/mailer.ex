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

  @spec send_heat_ticket(Feedback.Message.t, map()) :: {:ok, any} | {:error, any}
  def send_heat_ticket(message, photo_info) do
    request_response = if message.request_response, do: "Yes", else: "No"
    body =
      """
      <INCIDENT>
        <SERVICE>Inquiry</SERVICE>
        <CATEGORY>Other</CATEGORY>
        <TOPIC></TOPIC>
        <SUBTOPIC></SUBTOPIC>
        <MODE></MODE>
        <LINE></LINE>
        <STATION></STATION>
        <INCIDENTDATE></INCIDENTDATE>
        <VEHICLE></VEHICLE>
        <FIRSTNAME>#{format_first_name(message.name)}</FIRSTNAME>
        <LASTNAME>#{format_last_name(message.name)}</LASTNAME>
        <FULLNAME>#{format_name(message.name)}</FULLNAME>
        <CITY></CITY>
        <STATE></STATE>
        <ZIPCODE></ZIPCODE>
        <EMAILID>#{format_email(message.email)}</EMAILID>
        <PHONE>#{message.phone}</PHONE>
        <DESCRIPTION>#{message.comments}</DESCRIPTION>
        <CUSTREQUIRERESP>#{request_response}</CUSTREQUIRERESP>
        <MBTASOURCE>Auto Ticket 2</MBTASOURCE>
      </INCIDENT>
      """
    opts = [to: "heatsm@mbta.com",
            from: Application.get_env(:feedback, :support_ticket_from_email),
            subject: "MBTA Customer Comment Form",
            text: body]

    opts = if photo_info do
      [{:attachments, [photo_info]} | opts]
    else
      opts
    end

    Mailgun.Client.send_email config(), opts
  end

  defp format_name(nil) do
    "Riding Public"
  end
  defp format_name(name) do
    case String.trim(name) do
      "" -> "Riding Public"
      name -> name
    end
  end

  defp format_first_name(nil) do
    "Riding"
  end
  defp format_first_name(name) do
    case String.trim(name) do
      "" -> "Riding"
      name -> name
    end
  end

  defp format_last_name(nil) do
    "Public"
  end
  defp format_last_name(name) do
    case String.trim(name) do
      "" -> "Public"
      _name -> "-"
    end
  end

  defp format_email(nil) do
    "donotreply@mbta.com"
  end
  defp format_email(email) do
    case String.trim(email) do
      "" -> "donotreply@mbta.com"
      email -> email
    end
  end
end
