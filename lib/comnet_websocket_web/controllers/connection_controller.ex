defmodule ComnetWebsocketWeb.ConnectionController do
  @moduledoc """
  Controller for handling connection-related HTTP requests.

  This controller provides endpoints for querying active WebSocket
  connections and user presence information.
  """

  use ComnetWebsocketWeb, :controller
  alias ComnetWebsocketWeb.Presence
  alias ComnetWebsocket.Constants

  @doc """
  Returns statistics about active connections.

  ## Parameters
  - `conn` - The connection
  - `_params` - Request parameters (unused)

  ## Returns
  - JSON response with connection statistics
  """
  @spec active_connections(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def active_connections(conn, _params) do
    all = Presence.list("notification")

    guest_count =
      all
      |> Enum.count(fn {_id, %{metas: [meta | _]}} ->
        meta.type == Constants.presence_type_guest()
      end)

    user_count =
      all
      |> Enum.count(fn {_id, %{metas: [meta | _]}} ->
        meta.type == Constants.presence_type_user()
      end)

    json(conn, %{
      total: guest_count + user_count,
      guest_count: guest_count,
      user_count: user_count
    })
  end

  @doc """
  Returns a list of active user IDs.

  ## Parameters
  - `conn` - The connection
  - `_params` - Request parameters (unused)

  ## Returns
  - JSON response with list of active user IDs
  """
  @spec active_users(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def active_users(conn, _params) do
    users =
      Presence.list("notification")
      |> Enum.filter(fn {_id, %{metas: [meta | _]}} ->
        meta.type == Constants.presence_type_user()
      end)
      |> Enum.map(fn {_id, %{metas: [meta | _]}} ->
        %{
          user_id: meta.user_id,
          device_id: Map.get(meta, :device_id, nil),
          connection_id: Map.get(meta, :connection_id, nil)
        }
      end)

    json(conn, %{
      users: users
    })
  end
end
