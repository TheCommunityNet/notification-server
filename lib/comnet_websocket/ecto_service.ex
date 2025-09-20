defmodule ComnetWebsocket.EctoService do
  def save_notification(attrs \\ %{}) do
    attrs = Map.put(attrs, :key, Ecto.UUID.generate())
    attrs = Map.put(attrs, :sent_count, 0)
    attrs = Map.put(attrs, :received_count, 0)

    %ComnetWebsocket.Notification{}
    |> ComnetWebsocket.Notification.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
  end

  def save_notification_tracking(attrs \\ %{}) do
    %ComnetWebsocket.NotificationTracking{}
    |> ComnetWebsocket.NotificationTracking.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
  end
end
