defmodule ComnetWebsocket.EctoService do
  import Ecto.Query, only: [from: 2]

  def get_notifications_for_device(device_id) do
    query =
      from n in ComnetWebsocket.Notification,
        select: {n.key, n.payload},
        where: n.type == "device",
        left_join: nt in ComnetWebsocket.NotificationTracking,
        on: nt.notification_key == n.key and nt.device_id == ^device_id,
        where: not nt.is_received and not n.is_expired and n.expired_at > ^DateTime.utc_now()

    ComnetWebsocket.Repo.all(query)
  end

  def get_notifications_for_user(user_id) do
    query =
      from n in ComnetWebsocket.Notification,
        where: n.type == "user",
        left_join: nt in ComnetWebsocket.NotificationTracking,
        on: nt.notification_key == n.key,
        where: nt.user_id == ^user_id,
        where: not nt.is_received and not n.is_expired and n.expired_at > ^DateTime.utc_now()

    ComnetWebsocket.Repo.all(query)
  end

  def save_notification(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put_new(:key, Ecto.UUID.generate())
      |> Map.put_new(:sent_count, 0)
      |> Map.put_new(:received_count, 0)

    with {:ok, notification} <- create_notification(attrs),
         :ok <- create_tracking_records(notification.key, attrs) do
      {:ok, notification}
    end
  end

  defp create_notification(attrs) do
    %ComnetWebsocket.Notification{}
    |> ComnetWebsocket.Notification.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
  end

  defp create_tracking_records(notification_key, %{user_ids: user_ids}) when is_list(user_ids) do
    user_ids
    |> Enum.each(fn user_id ->
      save_notification_tracking(%{notification_key: notification_key, user_id: user_id})
    end)

    :ok
  end

  defp create_tracking_records(notification_key, %{user_id: user_id}) do
    save_notification_tracking(%{notification_key: notification_key, user_id: user_id})
    :ok
  end

  defp create_tracking_records(_notification_key, _attrs), do: :ok

  def save_notification_tracking(attrs \\ %{}) do
    attrs
    |> find_existing_tracking()
    |> upsert_tracking(attrs)
  end

  defp find_existing_tracking(%{user_id: user_id, notification_key: notification_key}) do
    ComnetWebsocket.Repo.get_by(ComnetWebsocket.NotificationTracking,
      notification_key: notification_key,
      user_id: user_id
    )
  end

  defp find_existing_tracking(%{device_id: device_id, notification_key: notification_key}) do
    ComnetWebsocket.Repo.get_by(ComnetWebsocket.NotificationTracking,
      notification_key: notification_key,
      device_id: device_id
    )
  end

  defp find_existing_tracking(_attrs), do: nil

  defp upsert_tracking(nil, attrs) do
    %ComnetWebsocket.NotificationTracking{}
    |> ComnetWebsocket.NotificationTracking.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
  end

  defp upsert_tracking(existing_tracking, attrs) do
    existing_tracking
    |> ComnetWebsocket.NotificationTracking.changeset(attrs)
    |> ComnetWebsocket.Repo.update()
  end

  def save_device(attrs \\ %{}) do
    attrs = Map.put_new(attrs, :last_active_at, DateTime.utc_now())

    %ComnetWebsocket.Device{}
    |> ComnetWebsocket.Device.changeset(attrs)
    |> ComnetWebsocket.Repo.insert!(
      on_conflict: [set: [last_active_at: attrs.last_active_at]],
      conflict_target: :device_id
    )
  end

  def save_device_activity(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put_new(:connection_id, Ecto.UUID.generate())
      |> Map.put_new(:started_at, DateTime.utc_now())

    %ComnetWebsocket.DeviceActivity{}
    |> ComnetWebsocket.DeviceActivity.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
  end

  def update_device_activity(attrs \\ %{}) do
    attrs = Map.put_new(attrs, :ended_at, DateTime.utc_now())

    ComnetWebsocket.Repo.get_by!(
      ComnetWebsocket.DeviceActivity,
      device_id: attrs.device_id,
      connection_id: attrs.connection_id
    )
    |> ComnetWebsocket.DeviceActivity.changeset(attrs)
    |> ComnetWebsocket.Repo.update()
  end
end
