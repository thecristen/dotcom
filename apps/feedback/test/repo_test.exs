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
      assert text =~ ~s(<EMAILID>test@mbtace.com</EMAILID>)
      assert text =~ ~s(<PHONE>555-555-5555</PHONE>)
      assert text =~ ~s(<FULLNAME>Charlie</FULLNAME>)
      assert text =~ ~s(<DESCRIPTION>comments</DESCRIPTION>)
    end
  end
end
