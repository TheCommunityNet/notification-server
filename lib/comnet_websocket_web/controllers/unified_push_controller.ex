defmodule ComnetWebsocketWeb.UnifiedPushController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.{Constants, Services.UnifiedPushAppService, Services.NotificationService}
  alias ComnetWebsocket.Models.{Notification, UnifiedPushApp}

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
              send_matrix_notification_to_device(unified_push_app, notification)
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
  defp send_matrix_notification_to_device(unified_push_app, notification) do
    # Broadcast to device via PubSub
    if unified_push_app.device_id do
      # Save notification to database before sending
      case save_notification_to_database(notification, unified_push_app) do
        {:ok, notification} ->
          IO.inspect(notification, label: "notification")

        # TODO: send notification to device via WebSocket
        # Phoenix.PubSub.broadcast(
        #   ComnetWebsocket.PubSub,
        #   "device:#{unified_push_app.device_id}",
        #   {:broadcast, message}
        # )

        {:error, _changeset} ->
          :error
      end
    end
  end

  # Save notification to database
  @spec save_notification_to_database(map(), UnifiedPushApp.t()) ::
          {:ok, Notification.t()} | {:error, Ecto.Changeset.t()}
  defp save_notification_to_database(notification, unified_push_app) do
    expired_at = DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second)

    %{
      type: Constants.notification_type_device(),
      category: "matrix",
      payload: %{
        app_id: unified_push_app.app_id,
        connector_token: unified_push_app.connector_token,
        payload: %{
          notification: notification
        }
      },
      expired_at: expired_at,
      is_expired: false,
      device_id: unified_push_app.device_id
    }
    |> NotificationService.save_notification()
  end

  def check(conn, _params) do
    json(conn, %{
      unifiedpush: %{
        gateway: "matrix"
      }
    })
  end
end
