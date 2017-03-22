defmodule News.BlurbTest do
  use ExUnit.Case, async: false
  use Quixir
  alias News.Blurb

  @suffix_length String.length(Blurb.suffix)
  @suffix_range Range.new(-1 * @suffix_length, -1)

  @max_blurb_length_padding String.duplicate("x", Blurb.max_length + 1)

  test "keeps string under or equal to max_length characters" do
    ptest x: string() do
      assert String.length(Blurb.blurb(x)) <= Blurb.max_length()
    end
  end

  test "ends with ... if original string was > max_length characters" do
    ptest x: string() do
      text = @max_blurb_length_padding <> x
      assert String.slice(Blurb.blurb(text), @suffix_range) == Blurb.suffix
    end
  end

  test "does not end with ... if original string was <= max_length characters" do
    ptest size: int(min: 1, max: Blurb.max_length) do
      str = String.duplicate("x", size)
      assert String.slice(Blurb.blurb(str), @suffix_range) != Blurb.suffix
    end
  end

  test "removes a paragraph if it contains 'Media Contact'" do
    ptest a: string(), b: string(), c: string(), d: string() do
      text = "<p>" <> a <> "Media Contact" <> b <> "</p>" <> c <> "<p>" <> d <> "</p>"
      assert Blurb.blurb(text) == Blurb.blurb(d)
    end
  end

  test "removes a paragraph if it starts with 'By'" do
    whitespace = ["", " ", "\t \r\n", "&nbsp;", "&#160;"] |> Enum.map(&value/1)
    ptest a: choose(from: whitespace), b: string(), c: string(), d: string() do
      text = "<p>" <> a <> "By " <> b <> "</p>" <> c <> "<p>" <> d <> "</p>"
      assert Blurb.blurb(text) == Blurb.blurb(d)
    end
  end

  test "returns a blurb from the first non-empty paragraph" do
    ptest a: string(), b: string(), c: string() do
      text = "<p>" <> a <> "</p>" <> b <> "<p>" <> c <> "</p>"
      actual = Blurb.blurb(text)
      expected = if String.strip(a) == "" do
        Blurb.blurb(c)
      else
        Blurb.blurb(a)
      end

      assert actual == expected
    end
  end

  @lint {Credo.Check.Readability.MaxLineLength, false}
  _ = @lint
  test "removes a paragraph if it contains 'Media Contact' and strips HTML tags" do
    text = "MBTA Debuts Performance Dashboard 2.0. Updated Dashboard Features Performance Trends over Time Plus Extra Stuff"
    html = "<p>Media Contact:MassDOT Press Office: 857-368-8500</p><p><b><hr>#{text}</p>"
    expected = Blurb.blurb(text)
    actual = Blurb.blurb(html)

    assert actual == expected
  end

end
