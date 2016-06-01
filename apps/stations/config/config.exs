# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

defmodule Stations.Config do
  @moduledoc "simple helper for config"
  def envvar_or_default(<<"$", _::binary>>, default) do
    default
  end
  def envvar_or_default(var, _) do
    var
  end
end

config :stations,
  base_url: Stations.Config.envvar_or_default("$STATION_URL", "http://mbta-station-info-dev.us-east-1.elasticbeanstalk.com")

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :stations, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:stations, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
