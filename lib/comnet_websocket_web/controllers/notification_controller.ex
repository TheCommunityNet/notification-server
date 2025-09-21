defmodule ComnetWebsocketWeb.NotificationController do
  use ComnetWebsocketWeb, :controller
  alias ComnetWebsocket.EctoService

  def send_notification(conn, %{
        "user_ids" => [_user_id | _] = user_ids,
        "payload" => %{"title" => _title, "content" => _content} = payload
      }) do
    # save to database
    case EctoService.save_notification(%{payload: payload, type: "user", user_ids: user_ids}) do
      {:ok, notification} ->
        message = %{
          id: notification.key,
          title: Map.get(payload, "title"),
          content: Map.get(payload, "content"),
          url: Map.get(payload, "url", nil)
        }

        # Broadcast to all specified users
        Enum.each(user_ids, fn user_id ->
          Phoenix.PubSub.broadcast(
            ComnetWebsocket.PubSub,
            "user:#{user_id}",
            {:broadcast, message}
          )
        end)

        json(conn, %{message: message})

      {:error, %Ecto.Changeset{} = changeset} ->
        json(conn, %{error: changeset})
    end
  end

  def send_notification(conn, %{
        "user_id" => user_id,
        "payload" => %{"title" => title, "content" => content} = payload
      }) do
    case EctoService.save_notification(%{
           payload: payload,
           sent_count: 1,
           type: "user",
           user_id: user_id
         }) do
      {:ok, notification} ->
        message = %{
          id: notification.key,
          title: title,
          content: content,
          url: Map.get(payload, "url", nil)
        }

        Phoenix.PubSub.broadcast(
          ComnetWebsocket.PubSub,
          "user:#{user_id}",
          {:broadcast, message}
        )

        json(conn, %{message: message})

      {:error, %Ecto.Changeset{} = changeset} ->
        json(conn, %{error: changeset})
    end
  end

  def send_notification(conn, %{
        "payload" => %{"title" => title, "content" => content} = payload
      }) do
    case EctoService.save_notification(%{payload: payload, type: "device"}) do
      {:ok, notification} ->
        message = %{
          id: notification.key,
          title: title,
          content: content,
          url: Map.get(payload, "url", nil)
        }

        ComnetWebsocketWeb.Endpoint.broadcast("notification", "message", message)

        json(conn, %{message: message})

      {:error, %Ecto.Changeset{} = changeset} ->
        json(conn, %{error: changeset})
    end
  end
end
