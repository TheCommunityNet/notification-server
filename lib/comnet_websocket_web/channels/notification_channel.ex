defmodule ComnetWebsocketWeb.NotificationChannel do
  @moduledoc """
  WebSocket channel for handling real-time notifications.

  This channel manages WebSocket connections for notifications, including
  user authentication, presence tracking, and message broadcasting.
  """

  use ComnetWebsocketWeb, :channel
  require Logger
  alias ComnetWebsocket.{Constants}
  alias ComnetWebsocket.Services.{DeviceService, NotificationService}
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
    with {:ok, received_at} <- parse_timestamp(received_at),
         {:ok, sent_at} <- parse_timestamp(sent_at) do
      now_timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      diff_timestamp = now_timestamp - sent_at
      received_at = DateTime.from_unix!(received_at + diff_timestamp, :millisecond)

      if String.starts_with?(notification_id, "g-") do
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
      else
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
      connection_id: socket.assigns.connection_id,
      ip_address: socket.assigns.ip_address,
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
        ip_address: socket.assigns.ip_address,
        online_at: DateTime.utc_now()
      })

    # Subscribe to device-specific notifications
    :ok = Phoenix.PubSub.subscribe(@pubsub, "device:#{socket.assigns.device_id}")

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
          push(socket, "message", NotificationService.build_websocket_message(notification))
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
        # Separate emergency and non-emergency notifications
        {emergency_notifications, other_notifications} =
          Enum.split_with(notifications, fn notification ->
            notification.category == Constants.notification_category_emergency()
          end)

        # Send emergency notifications immediately, one by one
        Enum.each(emergency_notifications, fn notification ->
          push(socket, "message", NotificationService.build_websocket_message(notification))
        end)

        # Group other notifications by category and send as groups
        other_notifications
        |> Enum.group_by(fn notification -> notification.category end)
        |> Enum.each(fn {_category, category_notifications} ->
          # Generate a UUID for this group
          group_key = "g-" <> Ecto.UUID.generate()

          # Update all notifications in this group with the group_key
          notification_keys = Enum.map(category_notifications, & &1.key)

          NotificationService.update_notifications_group_key(notification_keys, group_key)

          # Send all notifications of the same category as a group
          push(
            socket,
            "message",
            NotificationService.build_group_websocket_message(group_key, category_notifications)
          )
        end)
    end

    {:noreply, socket}
  end

  def leave(device_id, connection_id) do
    if connection_id do
      try do
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
      rescue
        e ->
          # Handle database connection errors gracefully, especially in test mode
          # when tasks don't have access to the sandbox connection
          Logger.debug("Failed to update device activity on leave: #{inspect(e)}")
          :ok
      catch
        :exit, reason ->
          # Handle process exit errors gracefully
          Logger.debug("Process exited while updating device activity: #{inspect(reason)}")
          :ok
      end
    else
      :ok
    end
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
