defmodule Mix.Tasks.Backstop.TestsTest do
  use ExUnit.Case, async: true
  alias Mix.Tasks.Backstop.Tests

  defmodule TestServer do
    use Backstop.Servers
    require Logger

    def command(%{dev: true}) do
      command = "sh -c 'sleep .25; echo dev_server'"
      IO.write command
      command
    end
    def command(_) do
      command = "sh -c 'sleep .25; echo prod_server'"
      IO.write command
      command
    end

    def started_match, do: "_server"

    def error_match, do: "error"
  end

  def runner_fn(args_map, parent, _cmd_fn) do
    send parent, {:ok, %{exit_code: 0, message: "runner_fn called", args: args_map, config: ""}}
  end

  def cmd_fn({config_path, %{scenarios: _, viewports: _}}, _cmd, _args, io_args) do
    assert config_path =~ "_backstop.json"
    System.cmd("sh", ["-c", "echo cmd_fn_called"], io_args)
  end

  describe "run/1" do
    test "starts servers and calls the runner task" do
      io = ExUnit.CaptureIO.capture_io(fn ->
        assert {:ok, result, pids} = Tests.run([], [TestServer], &runner_fn/3, &cmd_fn/4, 2000)
        assert [{TestServer, server_pid}] = pids
        assert is_pid(server_pid)
        assert result == %{exit_code: 0, message: "runner_fn called", args: %{}, config: ""}
      end)
      assert io =~ "prod_server"
    end

    test "calls cmd_fn" do
      io = ExUnit.CaptureIO.capture_io(fn ->
        assert {:ok, result, _pids} = Tests.run([], [TestServer], &Tests.run_backstop/3, &cmd_fn/4, 2000)
        assert %{exit_code: 0, args: _, config: _} = result
      end)
      assert io =~ "cmd_fn_called"
    end

    test "uses dev server when --dev option is used" do
      io = ExUnit.CaptureIO.capture_io(fn ->
        assert {:ok, _result, _pids} = Tests.run(["--dev"], [TestServer], &runner_fn/3, &cmd_fn/4, 2000)
      end)
      assert io =~ "dev_server"
    end
  end

  describe "run_backstop/2" do
    test "runs backstop with filter when --filter option is used" do
      io = ExUnit.CaptureIO.capture_io(fn ->
        assert {:ok, %{exit_code: 0, args: args, config: config}} =
          Tests.run_backstop(%{filter: "Homepage"}, self(), &cmd_fn/4)
        assert args == ["--config=" <> config, "--filter=Homepage"]
        assert String.slice(config, -14..-1) == "_backstop.json"
      end)
      assert io == "cmd_fn_called\n"
    end

    test "runs backstop without filter if --filter option is not used" do
      io = ExUnit.CaptureIO.capture_io(fn ->
        assert {:ok, %{exit_code: 0, args: args, config: config}} =
          Tests.run_backstop(%{}, self(), &cmd_fn/4)
        assert args == ["--config=" <> config]
        assert String.slice(config, -14..-1) == "_backstop.json"
      end)
      assert io == "cmd_fn_called\n"
    end
  end

  describe "build_backstop_arg_list/1" do
    test "returns the temp config file path, the map of configs, and the backstop proc args" do
      assert {path, %{scenarios: _, viewports: _}, arg_list} = Tests.build_backstop_args(%{}, self())
      assert path =~ "_backstop.json"
      assert arg_list == ["--config=#{path}"]
    end

    test "arg list has --filter=<<SCENARIO.LABEL>> when --filter in args" do
      assert {path, _config, arg_list} = Tests.build_backstop_args(%{filter: "Homepage"}, self())
      assert arg_list == ["--config=#{path}", "--filter=Homepage"]
    end
  end

  describe "build_backstop_config/1" do
    test "builds a map of config data without changing scenario urls when --dev not in args" do
      assert %{scenarios: scenarios, viewports: _} = Tests.build_backstop_config(%{})
      assert is_list scenarios
      assert Enum.all?(scenarios, & &1.url =~ "http://localhost:8082")
    end

    test "updates scenario urls to PORT when --dev in args and PORT env exists" do
      port = System.get_env("PORT")
      System.put_env("PORT", "1234")
      assert %{scenarios: scenarios} = Tests.build_backstop_config(%{dev: true})
      Enum.each(scenarios, & assert &1.url =~ "http://localhost:1234")
      if port, do: System.put_env("PORT", port), else: System.delete_env("PORT")
    end

    test "all scenario urls are 8082 when PORT == 8082" do
      port = System.get_env("PORT")
      System.put_env("PORT", "8082")
      assert %{scenarios: scenarios} = Tests.build_backstop_config(%{dev: true})
      assert Enum.all?(scenarios, & &1.url =~ "http://localhost:8082")
      if port, do: System.put_env("PORT", port), else: System.delete_env("PORT")
    end

    test "all scenario urls are 4001 when PORT == nil" do
      port = System.get_env("PORT")
      if port, do: System.delete_env("PORT")
      assert %{scenarios: scenarios} = Tests.build_backstop_config(%{dev: true})
      assert Enum.all?(scenarios, & &1.url =~ "http://localhost:4001")
      if port, do: System.put_env("PORT", port)
    end
  end
end
