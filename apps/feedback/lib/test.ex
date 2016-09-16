defmodule Feedback.Test do
  def latest_message do
    file = Application.get_env(:feedback, :test_mail_file)

    file
    |> File.read!
    |> Poison.decode!
  end
end
