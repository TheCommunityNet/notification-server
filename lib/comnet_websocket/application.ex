defmodule ComnetWebsocket.Application do
  @moduledoc """
  The ComnetWebsocket Application.

  This module defines the application's supervision tree and startup behavior.
  It manages all the core services including the database, WebSocket channels,
  notification services, and HTTP endpoints.
  """

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:my_sentry_handler, Sentry.LoggerHandler, %{
      config: %{
        metadata: [:file, :line],
        rate_limiting: [max_events: 10, interval: _1_second = 1_000],
        capture_log_messages: true
      }
    })

    children = [
      # Telemetry and monitoring
      ComnetWebsocketWeb.Telemetry,

      # Database
      ComnetWebsocket.Repo,

      # Clustering
      {DNSCluster, query: Application.get_env(:comnet_websocket, :dns_cluster_query) || :ignore},

      # PubSub for real-time communication
      {Phoenix.PubSub, name: ComnetWebsocket.PubSub},

      # Presence tracking
      ComnetWebsocketWeb.Presence,

      # Background services
      ComnetWebsocket.NotificationCheckExpireScheduler,
      {ComnetWebsocket.ChannelWatcher, :notifications},

      # HTTP endpoint (typically the last entry)
      ComnetWebsocketWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ComnetWebsocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Handles configuration changes.

  Tells Phoenix to update the endpoint configuration whenever the application is updated.

  ## Parameters
  - `changed` - Changed configuration
  - `_new` - New configuration (unused)
  - `removed` - Removed configuration

  ## Returns
  - `:ok`
  """
  @impl true
  def config_change(changed, _new, removed) do
    ComnetWebsocketWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
