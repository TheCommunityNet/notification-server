defmodule ComnetWebsocketWeb.NotificationSocket do
  use Phoenix.Socket

  channel "notification", ComnetWebsocketWeb.NotificationChannel

  @impl true
  def connect(%{"device_id" => device_id}, socket, _connect_info) do
    socket = assign(socket, :device_id, device_id)
    {:ok, socket}
  end

  @impl true
  def id(socket) do
    case socket.assigns[:user_id] do
      nil -> nil
      user_id -> "user:#{user_id}"
    end
  end
end
