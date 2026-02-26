defmodule ComnetWebsocketWeb.Admin.NotificationController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  import Ecto.Query

  alias ComnetWebsocket.{Repo, Constants}
  alias ComnetWebsocket.Models.Notification
  alias ComnetWebsocket.Services.NotificationService

  def index(conn, _params) do
    notifications =
      Repo.all(from n in Notification, order_by: [desc: n.inserted_at], limit: 100)

    render(conn, :index, page_title: "Notifications", notifications: notifications)
  end

  def send_notification(conn, %{"notification" => params}) do
    title = Map.get(params, "title", "")
    content = Map.get(params, "content", "")
    category = Map.get(params, "category", "normal")
    expired_in_hours = params |> Map.get("expired_in_hours", "24") |> parse_integer(24)

    expired_at =
      DateTime.utc_now()
      |> DateTime.add(expired_in_hours * 3600, :second)
      |> DateTime.truncate(:second)

    if String.trim(title) == "" or String.trim(content) == "" do
      conn
      |> put_flash(:error, "Title and content are required.")
      |> redirect(to: ~p"/admin/notifications")
    else
      attrs = %{
        payload: %{"title" => title, "content" => content},
        type: Constants.notification_type_device(),
        category: category,
        expired_at: expired_at
      }

      case NotificationService.save_notification(attrs) do
        {:ok, notification} ->
          message = NotificationService.build_websocket_message(notification)
          ComnetWebsocketWeb.Endpoint.broadcast("notification", "message", message)

          conn
          |> put_flash(:info, "Notification broadcast to all devices.")
          |> redirect(to: ~p"/admin/notifications")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to send notification.")
          |> redirect(to: ~p"/admin/notifications")
      end
    end
  end

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_integer(_, default), do: default
end
