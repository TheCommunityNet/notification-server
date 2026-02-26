defmodule ComnetWebsocketWeb.Admin.DashboardController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  alias ComnetWebsocket.Services.{UserService, ShellyService}
  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{ShellyAlert}
  alias ComnetWebsocket.Constants
  alias ComnetWebsocketWeb.Presence
  alias ComnetWebsocket.Services.NotificationService

  def index(conn, _params) do
    user_count = UserService.count_users()
    shelly_count = ShellyService.count_shellies()
    notification_count = NotificationService.count_notifications()
    alert_count = Repo.aggregate(ShellyAlert, :count)
    ws_connection_count = count_ws_connections()

    render(conn, :index,
      page_title: "Dashboard",
      user_count: user_count,
      shelly_count: shelly_count,
      notification_count: notification_count,
      alert_count: alert_count,
      ws_connection_count: ws_connection_count
    )
  end

  defp count_ws_connections do
    Presence.list("notification")
    |> Enum.count(fn {_key, %{metas: metas}} ->
      Enum.any?(metas, fn meta -> meta.type == Constants.presence_type_user() end)
    end)
  end
end
