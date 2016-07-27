defmodule News.BlurbTest do
  use ExUnit.Case, async: false
  use ExCheck
  alias News.Blurb

  @suffix_length String.length(Blurb.suffix)
  @suffix_range Range.new(-1 * @suffix_length, -1)

  property "keeps string under or equal to max_length characters" do
    for_all x in unicode_binary do
      String.length(Blurb.blurb(x)) <= Blurb.max_length
    end
  end

  property "ends with ... if original string was > max_length characters" do
    for_all x in unicode_binary do
      text = String.duplicate("x", Blurb.max_length + 1) <> x
      String.slice(Blurb.blurb(text), @suffix_range) == Blurb.suffix
    end
  end

  property "does not end with ... if original string was <= max_length characters" do
    for_all x in unicode_binary do
      implies String.length(x) <= Blurb.max_length && String.slice(x, -3..-1) != Blurb.suffix do
        String.slice(Blurb.blurb(x), @suffix_range) != Blurb.suffix
      end
    end
  end

  property "removes a paragraph if it contains 'Media Contact'" do
    for_all {a, b, c, d} in {unicode_binary, unicode_binary, unicode_binary, unicode_binary} do
      text = "<p>" <> a <> "Media Contact" <> b <> "</p>" <> c <> "<p>" <> d <> "</p>"
      Blurb.blurb(text) == Blurb.blurb(d)
    end
  end

  property "returns a blurb from the first non-empty paragraph" do
    for_all {a, b, c} in {unicode_binary, unicode_binary, unicode_binary} do
      text = "<p>" <> a <> "</p>" <> b <> "<p>" <> c <> "</p>"
      actual = Blurb.blurb(text)
      expected = if String.strip(a) == "" do
        Blurb.blurb(c)
      else
        Blurb.blurb(a)
      end

      actual == expected
    end
  end
end
