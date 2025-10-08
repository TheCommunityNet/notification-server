import Config

# Do not print debug messages in production
config :logger, level: :info

config :comnet_websocket, ComnetWebsocketWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST")],
  check_origin: false,
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
