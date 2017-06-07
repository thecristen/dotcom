defmodule Site.PhoneNumber do
  @moduledoc "Functions for working with phone numbers"

  @doc """
  Takes a string holding a possibly formatted phone number with optional
  leading 1 and presents it in the format 234-234-3456. Also supports 7
  digit phone numbers
  """
  @spec normalize(String.t) :: String.t
  def normalize(phone_string) do
    phone_string
    |> digits
    |> without_leading_one
    |> format
  end

  @spec digits(String.t) :: String.t
  defp digits(str) when is_binary(str) do
    String.replace(str, ~r/[^0-9]/, "")
  end

  @spec without_leading_one(String.t) :: String.t
  defp without_leading_one("1" <> rest), do: rest
  defp without_leading_one(phone), do: phone

  @spec format(String.t) :: String.t | nil
  defp format(<<prefix::bytes-size(3), line::bytes-size(4)>>) do
    "#{prefix}-#{line}"
  end
  defp format(<<area_code::bytes-size(3), prefix::bytes-size(3), line::bytes-size(4)>>) do
    "#{area_code}-#{prefix}-#{line}"
  end
  defp format(_incorrect_digits) do
    nil
  end
end
