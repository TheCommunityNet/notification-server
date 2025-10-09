defmodule ComnetWebsocketWeb.NotificationSocket do
  @moduledoc """
  WebSocket socket for handling notification connections.

  This socket manages WebSocket connections and handles device registration
  and activity tracking when devices connect.
  """

  use Phoenix.Socket
  alias ComnetWebsocket.DeviceService
  require Logger

  channel "notification", ComnetWebsocketWeb.NotificationChannel

  @impl true
  def connect(%{"device_id" => device_id}, socket, connect_info) do
    ip_address = get_ip_address(connect_info)

    socket = assign(socket, :device_id, device_id)
    socket = assign(socket, :ip_address, ip_address)

    DeviceService.save_device(%{device_id: device_id})

    socket =
      case DeviceService.save_device_activity(%{device_id: device_id, ip_address: ip_address}) do
        {:ok, device_activity} ->
          assign(socket, :connection_id, device_activity.connection_id)

        {:error, %Ecto.Changeset{} = changeset} ->
          Logger.error("Failed to save device activity: #{inspect(changeset)}")
          socket
      end

    {:ok, socket}
    # end
  end

  @impl true
  def id(socket) do
    case socket.assigns[:user_id] do
      nil -> nil
      user_id -> "user:#{user_id}"
    end
  end

  defp get_ip_address(%{x_headers: headers_list}) do
    header = Enum.find(headers_list, fn {key, _val} -> key == "x-forwarded-for" end)

    case header do
      nil ->
        nil

      {_key, value} ->
        value

      _ ->
        nil
    end
  end

  defp get_ip_address(_) do
    nil
  end
end
