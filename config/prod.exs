import Config

# Do not print debug messages in production
config :logger, level: :info

config :comnet_websocket, ComnetWebsocketWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto, :x_forwarded_for]
  ]

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
