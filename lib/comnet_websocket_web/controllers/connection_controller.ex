defmodule ComnetWebsocketWeb.ConnectionController do
  @moduledoc """
  Controller for handling connection-related HTTP requests.

  This controller provides endpoints for querying active WebSocket
  connections and user presence information.
  """

  use ComnetWebsocketWeb, :controller
  alias ComnetWebsocketWeb.Presence
  alias ComnetWebsocket.Constants
  alias ComnetWebsocket.DeviceService

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
    device_ids =
      Presence.list("notification")
      |> Enum.map(fn {id} ->
        id
      end)

    # Get user_ids for the device_ids from device_activities
    device_user_map = DeviceService.get_user_ids_by_device_ids(device_ids)

    users =
      Presence.list("notification")
      # |> Enum.filter(fn {_id, %{metas: [meta | _]}} ->
      #   meta.type == Constants.presence_type_user()
      # end)
      |> Enum.map(fn {id, %{metas: [meta | _]}} ->
        # Use user_id from meta if available, otherwise fall back to device_activities
        user_id = Map.get(meta, :user_id) || Map.get(device_user_map, id)

        %{
          device_id: id,
          user_id: user_id,
          ip_address: Map.get(meta, :ip_address, nil),
          connection_id: Map.get(meta, :connection_id, nil)
        }
      end)

    json(conn, %{
      users: users
    })
  end
end
