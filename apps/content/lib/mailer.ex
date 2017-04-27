defmodule Content.Mailer do
  @mailgun Application.get_env(:content, :mailgun)
  @emails Application.get_env(:content, :email)

  @config domain: @mailgun[:domain],
          key: @mailgun[:key],
          mode: @mailgun[:mode],
          test_file_path: @mailgun[:test_file_path]

  use Mailgun.Client, @config

  def meeting_migration_error_notice(reason, meeting_json) do
    send_email to: @emails[:developer_alert_address],
               from: @emails[:no_reply_address],
               subject: "Meeting Migration Task Failed",
               text: """
               Oh noes! The following error occurred
               when attempting to migrate a meeting.

               Meeting JSON:
               #{inspect meeting_json}

               Reason for Failure:
               #{reason}

               For more details, visit: #{drupal_logs_url()}
               """
  end

  defp drupal_logs_url do
    Content.Config.url("admin/reports/dblog")
  end
end
