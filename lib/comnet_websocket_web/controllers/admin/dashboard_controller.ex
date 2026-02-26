defmodule ComnetWebsocketWeb.Admin.DashboardController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  alias ComnetWebsocket.Services.{UserService, ShellyService}
  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.Notification

  def index(conn, _params) do
    user_count = UserService.count_users()
    shelly_count = ShellyService.count_shellies()
    notification_count = Repo.aggregate(Notification, :count)

    render(conn, :index,
      page_title: "Dashboard",
      user_count: user_count,
      shelly_count: shelly_count,
      notification_count: notification_count
    )
  end
end
