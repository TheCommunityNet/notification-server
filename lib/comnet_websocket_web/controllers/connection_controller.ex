defmodule ComnetWebsocketWeb.ConnectionController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocketWeb.Presence

  def active_connections(conn, _params) do
    all = Presence.list("notification")

    guest_count =
      all
      |> Enum.count(fn {_id, %{metas: [meta | _]}} -> meta.type == "guest" end)

    user_count =
      all
      |> Enum.count(fn {_id, %{metas: [meta | _]}} -> meta.type == "user" end)

    json(conn, %{
      total: guest_count + user_count,
      guest_count: guest_count,
      user_count: user_count
    })
  end

  def active_users(conn, _params) do
    user_ids =
      Presence.list("notification")
      |> Enum.filter(fn {_id, %{metas: [meta | _]}} -> meta.type == "user" end)
      |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta.user_id end)

    json(conn, %{
      user_ids: user_ids
    })
  end
end
