defmodule ComnetWebsocketWeb.NotificationController do
  @moduledoc """
  Controller for handling notification-related HTTP requests.

  This controller provides endpoints for sending notifications to users
  and devices via the WebSocket service.
  """

  use ComnetWebsocketWeb, :controller
  alias ComnetWebsocket.{Constants}
  alias ComnetWebsocket.Services.NotificationService

  plug ComnetWebsocketWeb.Plugs.ApiKeyAuth when action in [:send_notification]
  plug :check_rate_limit when action in [:get_notifications_by_device_id]

  # Rate limit check for get_notifications_by_device_id
  defp check_rate_limit(conn, _opts) do
    opts = [
      max_requests: 10,
      window_seconds: 60,
      key_func: fn conn -> Map.get(conn.path_params, "device_id") end
    ]

    ComnetWebsocketWeb.Plugs.RateLimit.call(conn, opts)
  end

  @doc """
  Gets unread notifications for a device, marks them as read, and returns them as websocket messages.

  ## Parameters
  - `conn` - The connection
  - `params` - Request parameters containing device_id

  ## Returns
  - JSON response with list of websocket messages
  """
  @spec get_notifications_by_device_id(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_notifications_by_device_id(conn, %{"device_id" => device_id}) do
    notifications =
      NotificationService.get_and_mark_notifications_as_read_for_device(device_id)
      |> Enum.map(&NotificationService.build_websocket_message/1)

    json(conn, %{data: notifications})
  end

  def get_notifications_by_device_id(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: Constants.error_invalid_params()})
  end

  @doc """
  Sends a notification to users or devices.

  ## Parameters
  - `conn` - The connection
  - `params` - Request parameters containing notification data

  ## Returns
  - JSON response with the notification message or error
  """
  @spec send_notification(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send_notification(conn, params) do
    with {:ok, notification_params} <- build_notification_params(params),
         {:ok, notification} <- NotificationService.save_notification(notification_params) do
      message = NotificationService.build_websocket_message(notification)
      broadcast_notification(params, message)

      json(conn, %{
        success: true,
        data: message
      })
    else
      {:error, :invalid_params} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: Constants.error_invalid_params()
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: changeset
        })
    end
  end

  @spec send_notification(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send_old_notification(conn, %{"device_ids" => device_ids} = params) do
    with {:ok, notification_params} <- build_notification_params(params) do
      message = %{
        id: Ecto.UUID.generate(),
        category: notification_params.category,
        title: notification_params.payload["title"],
        content: notification_params.payload["content"],
        is_dialog: false,
        expired_at: notification_params.expired_at
      }

      Enum.each(device_ids, fn device_id ->
        Phoenix.PubSub.broadcast(
          ComnetWebsocket.PubSub,
          "device:#{device_id}",
          {:broadcast, message}
        )
      end)

      json(conn, %{
        success: true,
        data: message
      })
    else
      {:error, :invalid_params} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: Constants.error_invalid_params()
        })
    end
  end

  # Build notification parameters based on input type
  @spec build_notification_params(map()) :: {:ok, map()} | {:error, :invalid_params}
  defp build_notification_params(%{
         "user_ids" => user_ids,
         "payload" => payload,
         "expired_at" => expired_at,
         "category" => category
       })
       when is_list(user_ids) and length(user_ids) > 0 do
    if valid_payload?(payload) do
      {:ok,
       %{
         payload: payload,
         type: Constants.notification_type_user(),
         user_ids: user_ids,
         expired_at: expired_at,
         category: category
       }}
    else
      {:error, :invalid_params}
    end
  end

  defp build_notification_params(%{
         "user_id" => user_id,
         "payload" => payload,
         "expired_at" => expired_at,
         "category" => category
       }) do
    if valid_payload?(payload) do
      {:ok,
       %{
         payload: payload,
         sent_count: 1,
         type: Constants.notification_type_user(),
         user_id: user_id,
         expired_at: expired_at,
         category: category
       }}
    else
      {:error, :invalid_params}
    end
  end

  defp build_notification_params(%{
         "payload" => payload,
         "expired_at" => expired_at,
         "category" => category
       }) do
    if valid_payload?(payload) do
      {:ok,
       %{
         payload: payload,
         type: Constants.notification_type_device(),
         expired_at: expired_at,
         category: category
       }}
    else
      {:error, :invalid_params}
    end
  end

  defp build_notification_params(_), do: {:error, :invalid_params}

  # Validate payload has required fields
  @spec valid_payload?(map()) :: boolean()
  defp valid_payload?(%{"title" => title, "content" => content})
       when is_binary(title) and is_binary(content),
       do: true

  defp valid_payload?(_), do: false

  # Handle broadcasting based on notification type
  defp broadcast_notification(%{"user_ids" => user_ids}, message) when is_list(user_ids) do
    Enum.each(user_ids, &broadcast_to_user(&1, message))
  end

  defp broadcast_notification(%{"user_id" => user_id}, message) do
    broadcast_to_user(user_id, message)
  end

  defp broadcast_notification(_, message) do
    ComnetWebsocketWeb.Endpoint.broadcast("notification", "message", message)
  end

  # Helper to broadcast to a specific user
  defp broadcast_to_user(user_id, message) do
    Phoenix.PubSub.broadcast(
      ComnetWebsocket.PubSub,
      "user:#{user_id}",
      {:broadcast, message}
    )
  end
end
