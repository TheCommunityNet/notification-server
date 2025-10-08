defmodule ComnetWebsocketWeb.NotificationChannel do
  @moduledoc """
  WebSocket channel for handling real-time notifications.

  This channel manages WebSocket connections for notifications, including
  user authentication, presence tracking, and message broadcasting.
  """

  use ComnetWebsocketWeb, :channel
  require Logger
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
        %{
          "device_id" => device_id,
          "notification_id" => notification_id,
          "received_at" => received_at,
          "sent_at" => sent_at
        } = payload,
        socket
      ) do
    IO.inspect(payload, label: "received")

    with {:ok, received_at} <- parse_timestamp(received_at),
         {:ok, sent_at} <- parse_timestamp(sent_at) do
      now_timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      diff_timestamp = now_timestamp - sent_at
      received_at = DateTime.from_unix!(received_at + diff_timestamp, :millisecond)

      # Check if notification_id is actually a group_key
      case NotificationService.get_notification_by_key(notification_id) do
        nil ->
          # notification_id might be a group_key, check for grouped notifications
          case NotificationService.get_notification_by_group_key(notification_id) do
            [] ->
              :ok

            group_notifications ->
              # Found group notifications, update tracking for all of them
              Enum.each(group_notifications, fn notification ->
                NotificationService.save_notification_tracking(%{
                  notification_key: notification.key,
                  user_id: Map.get(payload, "user_id"),
                  device_id: device_id,
                  received_at: received_at,
                  is_received: true
                })
              end)
          end

        _notification ->
          # Found single notification, save tracking normally
          NotificationService.save_notification_tracking(%{
            notification_key: notification_id,
            user_id: Map.get(payload, "user_id"),
            device_id: device_id,
            received_at: received_at,
            is_received: true
          })
      end

      {:noreply, socket}
    else
      {:error, :invalid_timestamp} ->
        Logger.error("Invalid timestamp for notification_id: #{notification_id}")
        {:noreply, socket}
    end
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
        connection_id: socket.assigns.connection_id,
        online_at: DateTime.utc_now()
      })

    ComnetWebsocket.ChannelWatcher.monitor(
      :notifications,
      self(),
      {__MODULE__, :leave,
       [socket.assigns.device_id, Map.get(socket.assigns, :connection_id, nil)]}
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
        IO.inspect(notifications, label: "notifications")
        # Separate emergency and non-emergency notifications
        {emergency_notifications, other_notifications} =
          Enum.split_with(notifications, fn notification ->
            notification.category == Constants.notification_category_emergency()
          end)

        # Send emergency notifications immediately, one by one
        Enum.each(emergency_notifications, fn notification ->
          push(socket, "message", build_notification_message(notification))
        end)

        # Group other notifications by category and send as groups
        other_notifications
        |> Enum.group_by(fn notification -> notification.category end)
        |> Enum.each(fn {category, category_notifications} ->
          # Generate a UUID for this group
          group_key = "g-" <> Ecto.UUID.generate()

          # Update all notifications in this group with the group_key
          notification_keys = Enum.map(category_notifications, & &1.key)

          NotificationService.update_notifications_group_key(notification_keys, group_key)

          [first_notification | _] = category_notifications
          # Send all notifications of the same category as a group
          push(socket, "message", %{
            id: group_key,
            category: category,
            is_dialog: false,
            title: Map.get(first_notification.payload, "title"),
            content: Map.get(first_notification.payload, "content"),
            url: Map.get(first_notification.payload, "url"),
            timestamp: first_notification.inserted_at |> DateTime.to_unix(:millisecond)
          })
        end)
    end

    {:noreply, socket}
  end

  def leave(device_id, connection_id) do
    if connection_id do
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
    else
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
      is_dialog: notification.category == Constants.notification_category_emergency(),
      timestamp: notification.inserted_at |> DateTime.to_unix(:millisecond)
    }
  end

  defp parse_timestamp(timestamp) when is_integer(timestamp), do: {:ok, timestamp}

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case Integer.parse(timestamp) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_timestamp}
    end
  end

  defp parse_timestamp(_), do: {:error, :invalid_timestamp}
end
