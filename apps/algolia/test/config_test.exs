defmodule Algolia.ConfigTest do
  use ExUnit.Case, async: true

  @config Application.get_env(:algolia, :config)

  describe "Algolia.Config.config/0" do
    test "builds a config object with all values populated" do
      log = ExUnit.CaptureLog.capture_log(fn ->
        assert %Algolia.Config{
          app_id: <<_::binary>>,
          admin: <<_::binary>>,
          search: <<_::binary>>,
          places: %Algolia.Config.Places{
            app_id: <<_::binary>>,
            search: <<_::binary>>
          }
        } = Algolia.Config.config()
      end)
      assert log == ""
    end

    test "logs a warning if keys were not parsed" do
      log = ExUnit.CaptureLog.capture_log(fn ->
        Application.put_env(:algolia, :config, Keyword.update!(@config, :app_id, fn _ -> "${ALGOLIA_APP_ID}" end))
        Algolia.Config.config()
      end)
      Application.put_env(:algolia, :config, @config)
      assert log =~ "unparsed"
      assert log =~ "ALGOLIA_APP_ID"
    end

    test "logs a warning if keys are missing" do
      log = ExUnit.CaptureLog.capture_log(fn ->
        Application.put_env(:algolia, :config, Keyword.update!(@config, :app_id, fn _ -> {:system, "DOES_NOT_EXIST"} end))
        Algolia.Config.config()
      end)
      Application.put_env(:algolia, :config, @config)
      assert log =~ "missing"
      assert log =~ ":app_id"
    end
  end
end
