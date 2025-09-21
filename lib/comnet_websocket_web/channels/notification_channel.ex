defmodule ComnetWebsocketWeb.NotificationChannel do
  use ComnetWebsocketWeb, :channel
  alias ComnetWebsocket.EctoService
  alias ComnetWebsocketWeb.Presence

  @pubsub ComnetWebsocket.PubSub

  @impl true
  def join("notification", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (ws:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in(
        "received",
        %{"id" => id, "received_at" => received_at} = payload,
        socket
      ) do
    EctoService.save_notification_tracking(%{
      notification_key: id,
      user_id: Map.get(payload, "user_id"),
      device_id: socket.assigns.device_id,
      received_at: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  def handle_in("connect", %{"user_id" => user_id}, socket) do
    :ok = Phoenix.PubSub.subscribe(@pubsub, "user:#{user_id}")

    Presence.untrack(socket, socket.assigns.device_id)

    Presence.track(socket, socket.assigns.device_id, %{
      type: "user",
      user_id: user_id,
      online_at: DateTime.utc_now()
    })

    send(self(), :after_connect)

    {:reply, {:ok, %{msg: "logged in"}}, assign(socket, :user_id, user_id)}
  end

  @impl true
  def handle_info({:broadcast, payload}, socket) do
    push(socket, "message", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.device_id, %{
        type: if(socket.assigns[:user_id] != nil, do: "user", else: "guest"),
        online_at: DateTime.utc_now()
      })

    # send all notifications for the device
    case EctoService.get_notifications_for_device(socket.assigns.device_id) do
      notifications when is_list(notifications) ->
        Enum.each(notifications, fn notification ->
          push(socket, "message", %{
            id: notification.key,
            title: Map.get(notification.payload, "title"),
            content: Map.get(notification.payload, "content"),
            url: Map.get(notification.payload, "url", nil)
          })
        end)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_connect, socket) do
    # send all notifications for the device
    case EctoService.get_notifications_for_user(socket.assigns.user_id) do
      notifications when is_list(notifications) ->
        IO.inspect(notifications, label: "notifications")

        Enum.each(notifications, fn notification ->
          push(socket, "message", %{
            id: notification.key,
            title: Map.get(notification.payload, "title"),
            content: Map.get(notification.payload, "content"),
            url: Map.get(notification.payload, "url", nil)
          })
        end)

      _ ->
        :ok
    end

    {:noreply, socket}
  end
end
