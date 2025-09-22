defmodule ComnetWebsocketWeb.NotificationController do
  @moduledoc """
  Controller for handling notification-related HTTP requests.

  This controller provides endpoints for sending notifications to users
  and devices via the WebSocket service.
  """

  use ComnetWebsocketWeb, :controller
  alias ComnetWebsocket.{NotificationService, Constants}

  plug ComnetWebsocketWeb.Plugs.ApiKeyAuth when action in [:send_notification]

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
      message = build_message(notification, params["payload"])
      broadcast_notification(params, message)
      json(conn, %{message: message})
    else
      {:error, :invalid_params} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: Constants.error_invalid_params()})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: changeset})
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

  # Build the message map from notification and payload
  @spec build_message(ComnetWebsocket.Notification.t(), map()) :: map()
  defp build_message(notification, payload) do
    %{
      id: notification.key,
      title: payload["title"],
      content: payload["content"],
      url: payload["url"],
      category: notification.category,
      is_dialog: notification.category == Constants.notification_category_emergency()
    }
  end

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
