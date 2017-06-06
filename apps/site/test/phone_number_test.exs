defmodule Site.PhoneNumberTest do
  use ExUnit.Case, async: true

  import Site.PhoneNumber

  describe "formats a phone number correctly" do
    test "removes optional leading 1 if present" do
      assert normalize("1-345-345-3456") == "345-345-3456"
    end

    test "strips other formatting" do
      assert normalize("(345) 345-3456") == "345-345-3456"
      assert normalize("345.345.3456") == "345-345-3456"
    end

    test "returns the empty string if incorrect number of digits" do
      assert normalize("345-345-345") == nil
      assert normalize("234-234-23456") == nil
    end

    test "allows 7 digit numbers" do
      assert normalize("345-3456") == "345-3456"
    end
  end
end
