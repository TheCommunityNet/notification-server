defmodule ComnetWebsocketWeb.NotificationSocket do
  use Phoenix.Socket
  alias ComnetWebsocket.EctoService
  channel "notification", ComnetWebsocketWeb.NotificationChannel

  @impl true
  def connect(%{"device_id" => device_id}, socket, _connect_info) do
    socket = assign(socket, :device_id, device_id)

    EctoService.save_device(%{device_id: device_id})

    case EctoService.save_device_activity(%{device_id: device_id}) do
      {:ok, device_activity} ->
        assign(socket, :connection_id, device_activity.connection_id)

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "error saving device activity")
    end

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
