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
  describe "send_heat_ticket/2" do
    test "sends an email for heat 2" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{comments: ""}, nil)
      assert Feedback.Test.latest_message["to"] == "heatsm@mbta.com"
    end

    test "has the body format that heat 2 expects" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{comments: ""}, nil)
      assert Feedback.Test.latest_message["text"] ==
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
          <FIRSTNAME></FIRSTNAME>
          <LASTNAME></LASTNAME>
          <FULLNAME>Riding Public</FULLNAME>
          <CITY></CITY>
          <STATE></STATE>
          <ZIPCODE></ZIPCODE>
          <EMAILID>donotreply@mbta.com</EMAILID>
          <PHONE></PHONE>
          <DESCRIPTION></DESCRIPTION>
          <CUSTREQUIRERESP>No</CUSTREQUIRERESP>
          <MBTASOURCE>Auto Ticket 2</MBTASOURCE>
        </INCIDENT>
        """
    end

    test "uses the comments of the message for the description" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{comments: "major issue to report"}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<DESCRIPTION>major issue to report</DESCRIPTION>"
    end

    test "uses the phone from the message in the phone field" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{phone: "617-123-4567"}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<PHONE>617-123-4567</PHONE>"
    end

    test "sets the emailid to the one provided by the user" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{email: "disgruntled@user.com"}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<EMAILID>disgruntled@user.com</EMAILID>"
    end

    test "when the user does not set an email, the email is donotreply@mbta.com" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<EMAILID>donotreply@mbta.com</EMAILID>"
    end

    test "the email does not have leading or trailing spaces" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{email: "   fake_email@gmail.com  "}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<EMAILID>fake_email@gmail.com</EMAILID>"
    end

    test "gives the full name as the name the user provided" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{name: "My Full Name"}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<FULLNAME>My Full Name</FULLNAME>"
    end

    test "if the user does not provide a name, sets the full name to riding public" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{name: ""}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<FULLNAME>Riding Public</FULLNAME>"
    end

    test "sets customer requests response to no" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{}, nil)
      assert Feedback.Test.latest_message["text"] =~ "<CUSTREQUIRERESP>No</CUSTREQUIRERESP>"
    end

    test "can attach a photo" do
      Feedback.Mailer.send_heat_ticket(%Feedback.Message{}, %{path: "/tmp/nonsense.txt", filename: "test.png"})
      assert List.first(Feedback.Test.latest_message["attachments"]) == %{
        "path" => "/tmp/nonsense.txt",
        "filename" => "test.png"
      }
    end
  end
end
