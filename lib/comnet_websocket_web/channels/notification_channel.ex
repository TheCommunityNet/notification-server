defmodule ComnetWebsocketWeb.NotificationChannel do
  @moduledoc """
  WebSocket channel for handling real-time notifications.

  This channel manages WebSocket connections for notifications, including
  user authentication, presence tracking, and message broadcasting.
  """

  use ComnetWebsocketWeb, :channel
  alias ComnetWebsocket.DeviceService
  alias ComnetWebsocket.{NotificationService, Constants}
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
        %{"id" => id, "received_at" => _received_at} = payload,
        socket
      ) do
    NotificationService.save_notification_tracking(%{
      notification_key: id,
      user_id: Map.get(payload, "user_id"),
      device_id: socket.assigns.device_id,
      received_at: DateTime.utc_now(),
      is_received: true
    })

    {:noreply, socket}
  end

  def handle_in("connect", %{"user_id" => user_id}, socket) do
    :ok = Phoenix.PubSub.subscribe(@pubsub, "user:#{user_id}")

    Presence.untrack(socket, socket.assigns.device_id)

    Presence.track(socket, socket.assigns.device_id, %{
      type: Constants.presence_type_user(),
      user_id: user_id,
      online_at: DateTime.utc_now()
    })

    send(self(), :after_connect)

    {:reply, {:ok, %{msg: Constants.api_message_logged_in()}}, assign(socket, :user_id, user_id)}
  end

  @impl true
  def handle_info({:broadcast, payload}, socket) do
    push(socket, "message", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    presence_type =
      if socket.assigns[:user_id] != nil,
        do: Constants.presence_type_user(),
        else: Constants.presence_type_guest()

    {:ok, _} =
      Presence.track(socket, socket.assigns.device_id, %{
        type: presence_type,
        online_at: DateTime.utc_now()
      })

    ComnetWebsocket.ChannelWatcher.monitor(
      :notifications,
      self(),
      {__MODULE__, :leave, [socket.assigns.device_id, socket.assigns.connection_id]}
    )

    # send all notifications for the device
    case NotificationService.get_notifications_for_device(socket.assigns.device_id) do
      notifications when is_list(notifications) ->
        Enum.each(notifications, fn notification ->
          push(socket, "message", build_notification_message(notification))
        end)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_connect, socket) do
    # send all notifications for the user
    DeviceService.update_device_activity(%{
      device_id: socket.assigns.device_id,
      connection_id: socket.assigns.connection_id,
      user_id: socket.assigns.user_id
    })

    case NotificationService.get_notifications_for_user(socket.assigns.user_id) do
      notifications when is_list(notifications) ->
        Enum.each(notifications, fn notification ->
          push(socket, "message", build_notification_message(notification))
        end)
    end

    {:noreply, socket}
  end

  def leave(device_id, connection_id) do
    case DeviceService.update_device_activity(%{
           device_id: device_id,
           connection_id: connection_id,
           ended_at: DateTime.utc_now()
         }) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        :ok
    end
  end

  # Private helper functions

  @spec build_notification_message(ComnetWebsocket.Notification.t()) :: map()
  defp build_notification_message(notification) do
    %{
      id: notification.key,
      category: notification.category,
      title: Map.get(notification.payload, "title"),
      content: Map.get(notification.payload, "content"),
      url: Map.get(notification.payload, "url", nil),
      is_dialog: notification.category == Constants.notification_category_emergency()
    }
  end
end
