defmodule Feedback.RepoTest do
  use ExUnit.Case, async: true

  describe "Feedback.Repo" do
    test "renders a message into the HEAT email format" do
      %Feedback.Message{
        email: "test@mbtace.com",
        phone: "555-555-5555",
        name: "Charlie",
        comments: "comments"
      }
      |> Feedback.Repo.send_ticket

      text = Feedback.Test.latest_message["text"]
      assert text =~ "EMAILID: test@mbtace.com"
      assert text =~ "Phone: 555-555-5555"
      assert text =~ "Incident Date: " <> Timex.format!(
        Timex.to_date(Timex.now("America/New_York")),
        "{0M}/{D}/{YYYY}"
      )
      assert text =~ "Name: Charlie"
      assert text =~ "Comments: comments"
    end
  end
end
