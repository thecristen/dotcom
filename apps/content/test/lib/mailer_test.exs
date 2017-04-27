defmodule Content.MailerTest do
  use Content.EmailCase
  import Content.Mailer

  describe "meeting_migration_error_notice/2" do
    test "notifes the dev team that the meeting migration task failed" do
      meeting = %{"location" => "MassDOT"}
      reason = "Likely to be a CMS or event validation error"

      meeting_migration_error_notice(reason, meeting)

      assert email("to") == "devops-alerts@mbtace.com"
      assert email("from") == "noreply@mbtace.com"
      assert email("subject") == "Meeting Migration Task Failed"
      assert email("text") =~ "Meeting JSON:\n%{\"location\" => \"MassDOT\""
      assert email("text") =~ reason
    end
  end
end
