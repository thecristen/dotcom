defmodule Content.MailerTest do
  use Content.EmailCase
  import Content.Mailer

  describe "migration_error_notice/2" do
    test "notifes the dev team that the migration task failed" do
      meeting = %{"location" => "MassDOT"}
      reason = "Likely to be a CMS or validation error"

      migration_error_notice(reason, meeting)

      assert email("to") == "devops-alerts@mbtace.com"
      assert email("from") == "noreply@mbtace.com"
      assert email("subject") == "CMS Migration Task Failed"
      assert email("text") =~ "JSON:\n%{\"location\" => \"MassDOT\""
      assert email("text") =~ reason
    end

    test "given the reason is a map" do
      meeting = %{"location" => "MassDOT"}
      reason = %{reason: :econnrefused}

      migration_error_notice(reason, meeting)

      assert email("text") =~ "%{reason: :econnrefused}"
    end
  end
end
