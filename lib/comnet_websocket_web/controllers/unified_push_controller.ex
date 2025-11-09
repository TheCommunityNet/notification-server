defmodule ComnetWebsocketWeb.UnifiedPushController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.UnifiedPushAppService

  def send_notification(conn, params) do
    # Matrix Push Gateway notification format:
    # {
    #   "notification": {
    #     "event_id": "...",
    #     "room_id": "...",
    #     "type": "...",
    #     "sender": "...",
    #     "content": {...},
    #     "devices": [
    #       {
    #         "app_id": "...",
    #         "pushkey": "...",
    #         "data": {...}
    #       }
    #     ]
    #   }
    # }
    IO.inspect(params, label: "params")
    notification = params["notification"]

    if notification && is_map(notification) do
      devices = Map.get(notification, "devices", [])
      rejected = process_matrix_notification(notification, devices)
      json(conn, %{rejected: rejected})
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid notification format"})
    end
  end

  # Process Matrix notification and send to devices
  defp process_matrix_notification(notification, devices) do
    Enum.reduce(devices, [], fn device, rejected ->
      push_key = Map.get(device, "pushkey")
      IO.inspect(push_key, label: "push_key")

      # Extract ID from push_key URL path
      # Pushkey format: "api/v1/unified_push/{id}/send" or "https://domain.com/api/v1/unified_push/{id}/send"
      case extract_id_from_push_key(push_key) do
        {:ok, id} ->
          case UnifiedPushAppService.find_unified_push_app_by_id(id) do
            {:ok, unified_push_app} ->
              send_matrix_notification_to_device(unified_push_app, notification, device)
              rejected

            {:error, :not_found} ->
              # Unified push app not found, add pushkey to rejected list
              [push_key | rejected]
          end

        {:error, :invalid_push_key} ->
          # Invalid pushkey format, add to rejected list
          [push_key | rejected]
      end
    end)
  end

  # Extract ID from pushkey URL path
  # Supports formats:
  # - "api/v1/unified_push/{id}/send"
  # - "https://domain.com/api/v1/unified_push/{id}/send"
  # - "/api/v1/unified_push/{id}/send"
  defp extract_id_from_push_key(push_key) when is_binary(push_key) do
    # Use regex to extract UUID from the path
    case Regex.run(~r/unified_push\/([a-f0-9\-]+)\/send/i, push_key) do
      [_, id] -> {:ok, id}
      _ -> {:error, :invalid_push_key}
    end
  end

  defp extract_id_from_push_key(_), do: {:error, :invalid_push_key}

  # Send Matrix notification to device via WebSocket
  defp send_matrix_notification_to_device(unified_push_app, notification, device) do
    # Build notification message from Matrix format
    message = build_matrix_message(notification, device)

    # Broadcast to device via PubSub
    if unified_push_app.device_id do
      Phoenix.PubSub.broadcast(
        ComnetWebsocket.PubSub,
        "device:#{unified_push_app.device_id}",
        {:broadcast, message}
      )
    end
  end

  # Build notification message from Matrix notification format
  defp build_matrix_message(notification, device) do
    content = Map.get(notification, "content", %{})
    event_id = Map.get(notification, "event_id")
    room_id = Map.get(notification, "room_id")
    sender = Map.get(notification, "sender")

    # Extract title and body from Matrix content
    # Matrix content format varies, but typically has "body" and sometimes "msgtype"
    body = Map.get(content, "body", "")
    msgtype = Map.get(content, "msgtype", "m.text")

    # Build title from room_id or sender
    title =
      cond do
        room_id -> "Matrix: #{room_id}"
        sender -> "Matrix: #{sender}"
        true -> "Matrix Notification"
      end

    %{
      id: Ecto.UUID.generate(),
      title: title,
      content: body,
      url: nil,
      category: "matrix",
      is_dialog: false,
      timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      matrix: notification
    }
  end

  def check(conn, _params) do
    json(conn, %{
      unifiedpush: %{
        gateway: "matrix"
      }
    })
  end
end
