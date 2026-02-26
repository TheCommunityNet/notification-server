# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :comnet_websocket,
  ecto_repos: [ComnetWebsocket.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :comnet_websocket, ComnetWebsocketWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ComnetWebsocketWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ComnetWebsocket.PubSub,
  live_view: [signing_salt: "w+lPYe6m"]

config :comnet_websocket, ComnetWebsocket.Repo, migration_primary_key: [name: :id, type: :uuid]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Admin dashboard credentials (override in runtime.exs for production)
config :comnet_websocket, :admin_auth,
  username: System.get_env("ADMIN_USERNAME", "admin"),
  password: System.get_env("ADMIN_PASSWORD", "admin")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
