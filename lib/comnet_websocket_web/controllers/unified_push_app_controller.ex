defmodule ComnetWebsocketWeb.UnifiedPushAppController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.UnifiedPushAppService

  def create(conn, %{
        "app_id" => app_id,
        "connector_token" => connector_token,
        "device_id" => device_id
      }) do
    case UnifiedPushAppService.create_unified_push_app(%{
           app_id: app_id,
           connector_token: connector_token,
           device_id: device_id
         }) do
      {:ok, unified_push_app} ->
        json(conn, %{
          success: true,
          message: "Unified push app created successfully",
          url: "https://#{conn.host}/api/v1/unified_push/#{unified_push_app.id}/send"
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: changeset
        })
    end
  end

  def delete(conn, %{
        "app_id" => app_id,
        "connector_token" => connector_token,
        "device_id" => device_id
      }) do
    case UnifiedPushAppService.delete_unified_push_app(%{
           app_id: app_id,
           connector_token: connector_token,
           device_id: device_id
         }) do
      {:ok, _} ->
        json(conn, %{
          message: "Unified push app deleted successfully"
        })
    end
  end

  def matrix_notify(conn, params) do
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
      pushkey = Map.get(device, "pushkey")
      IO.inspect(pushkey, label: "pushkey")

      case UnifiedPushAppService.find_unified_push_app_by_pushkey(pushkey) do
        {:ok, unified_push_app} ->
          send_matrix_notification_to_device(unified_push_app, notification, device)
          rejected

        {:error, :not_found} ->
          # Pushkey not found, add to rejected list
          [pushkey | rejected]
      end
    end)
  end

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
      id: event_id || Ecto.UUID.generate(),
      title: title,
      content: body,
      url: nil,
      category: "matrix",
      is_dialog: false,
      timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      matrix: %{
        event_id: event_id,
        room_id: room_id,
        sender: sender,
        msgtype: msgtype,
        data: Map.get(device, "data", %{})
      }
    }
  end

  def matrix_notify_check(conn, _params) do
    json(conn, %{
      unifiedpush: %{
        gateway: "matrix"
      }
    })
  end
end
