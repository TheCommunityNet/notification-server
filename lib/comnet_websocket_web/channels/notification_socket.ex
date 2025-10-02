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
  def connect(%{"device_id" => device_id}, socket, _connect_info) do
    if device_id == "4db7879518da3afa" or device_id == "2a2f1f7d4eadcd57" do
      {:error, %{reason: "unauthorized"}}
    else
      socket = assign(socket, :device_id, device_id)

      DeviceService.save_device(%{device_id: device_id})

      socket =
        case DeviceService.save_device_activity(%{device_id: device_id}) do
          {:ok, device_activity} ->
            assign(socket, :connection_id, device_activity.connection_id)

          {:error, %Ecto.Changeset{} = changeset} ->
            Logger.error("Failed to save device activity: #{inspect(changeset)}")
            socket
        end

      {:ok, socket}
    end
  end

  @impl true
  def id(socket) do
    case socket.assigns[:user_id] do
      nil -> nil
      user_id -> "user:#{user_id}"
    end
  end
end
