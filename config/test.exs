import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :comnet_websocket, ComnetWebsocket.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "comnet_websocket_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :comnet_websocket, ComnetWebsocketWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "f1D9dj8P4f4xyCZiX6rG82nufg/eBpESzLLvsGoJj+jfSqXqIuzS0EjaxcvzT5T/",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
