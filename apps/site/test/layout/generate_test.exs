defmodule Layout.GenerateTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Mix.Tasks.Layout.Generate
  import Mock

  describe "run/1" do
    test "mix runs the task and the generated template doesn't change" do
      output_folder = System.tmp_dir!() |> Path.join("layout-generate")

      on_exit fn ->
        _ = File.rm_rf(output_folder)
      end

      :ok = File.mkdir_p(output_folder)
      assert File.ls(output_folder) == {:ok, []}

      Generate.run(["--output-folder=#{output_folder}"])
      assert {:ok, files} = File.ls(output_folder)
      assert Enum.member?(files, "_header.html")
      assert Enum.member?(files, "_footer.html")
      assert Enum.member?(files, "collapse.js")
    end
  end

  describe "generate_html/1" do
    test "generates the expected html from a template file" do
      with_mock Phoenix.View, [render_to_string: fn(_, _, _) -> "<div><%= test =></div>" end] do
        expected = {"test", "<div><%= test =></div>"}
        actual = Generate.generate_html("test")
        assert actual == expected
      end
    end

    test "renders _header.html" do
      assert {"_header.html", html} = Generate.generate_html("_header.html")
      assert {"header", _, _} = Floki.parse(html)
    end

    test "renders _footer.html" do
      assert {"_footer.html", html} = Generate.generate_html("_footer.html")
      assert {"footer", _, _} = Floki.parse(html)
    end
  end

  test "js_file_path points to the correct JS file" do
    path = Generate.js_file_path()
    assert path =~ "apps/site/assets/node_modules/bootstrap/dist/js/umd/collapse.js"
    assert File.exists?(path)
  end
end

