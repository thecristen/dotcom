defmodule Feedback.MailerTest do
  use ExUnit.Case, async: true

  describe "Feedback.Mailer" do

    test "sends an email" do
      Feedback.Mailer.send_ticket("foo", nil)
      assert Feedback.Test.latest_message["text"] == "foo"
    end

    test "can attach a photo" do
      Feedback.Mailer.send_ticket("foo", %{path: "/tmp/nonsense.txt", filename: "test.png"})
      assert List.first(Feedback.Test.latest_message["attachments"]) == %{
        "path" => "/tmp/nonsense.txt",
        "filename" => "test.png"
      }
    end
  end
end
