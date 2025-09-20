defmodule ComnetWebsocketWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :comnet_websocket,
    pubsub_server: ComnetWebsocket.PubSub
end
