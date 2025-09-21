defmodule ComnetWebsocket.EctoService do
  import Ecto.Query, only: [from: 2]

  def get_notifications_for_device(device_id) do
    query =
      from n in ComnetWebsocket.Notification,
        where: n.type == "device",
        left_join: nt in ComnetWebsocket.NotificationTracking,
        on: nt.notification_key == n.key and nt.device_id == ^device_id,
        where: is_nil(nt.received_at)

    ComnetWebsocket.Repo.all(query)
  end

  def get_notifications_for_user(user_id) do
    query =
      from n in ComnetWebsocket.Notification,
        where: n.type == "user",
        left_join: nt in ComnetWebsocket.NotificationTracking,
        on: nt.notification_key == n.key,
        where: nt.user_id == ^user_id,
        where: is_nil(nt.received_at)

    ComnetWebsocket.Repo.all(query)
  end

  def save_notification(attrs \\ %{}) do
    attrs = Map.put(attrs, :key, Ecto.UUID.generate())
    attrs = Map.put(attrs, :sent_count, 0)
    attrs = Map.put(attrs, :received_count, 0)

    %ComnetWebsocket.Notification{}
    |> ComnetWebsocket.Notification.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
    |> case do
      {:ok, notification} ->
        case attrs do
          %{user_ids: user_ids} ->
            Enum.each(user_ids, fn user_id ->
              save_notification_tracking(%{notification_key: notification.key, user_id: user_id})
            end)

          %{user_id: user_id} ->
            save_notification_tracking(%{notification_key: notification.key, user_id: user_id})

          _ ->
            :ok
        end

        {:ok, notification}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  def save_notification_tracking(attrs \\ %{}) do
    existing_tracking =
      case attrs do
        %{user_id: user_id} ->
          ComnetWebsocket.Repo.get_by(ComnetWebsocket.NotificationTracking,
            notification_key: attrs.notification_key,
            user_id: user_id
          )

        %{device_id: device_id} ->
          ComnetWebsocket.Repo.get_by(ComnetWebsocket.NotificationTracking,
            notification_key: attrs.notification_key,
            device_id: device_id
          )

        _ ->
          nil
      end

    if existing_tracking do
      existing_tracking
      |> ComnetWebsocket.NotificationTracking.changeset(attrs)
      |> ComnetWebsocket.Repo.update()
    else
      %ComnetWebsocket.NotificationTracking{}
      |> ComnetWebsocket.NotificationTracking.changeset(attrs)
      |> ComnetWebsocket.Repo.insert()
    end
  end

  def save_device(attrs \\ %{}) do
    attrs = Map.put(attrs, :last_active_at, DateTime.utc_now())

    %ComnetWebsocket.Device{}
    |> ComnetWebsocket.Device.changeset(attrs)
    |> ComnetWebsocket.Repo.insert!(
      on_conflict: [set: [last_active_at: attrs.last_active_at]],
      conflict_target: :device_id
    )
  end

  def save_device_activity(attrs \\ %{}) do
    attrs = Map.put(attrs, :connection_id, Ecto.UUID.generate())
    attrs = Map.put(attrs, :started_at, DateTime.utc_now())

    %ComnetWebsocket.DeviceActivity{}
    |> ComnetWebsocket.DeviceActivity.changeset(attrs)
    |> ComnetWebsocket.Repo.insert()
  end

  def update_device_activity(attrs \\ %{}) do
    attrs = Map.put(attrs, :ended_at, DateTime.utc_now())

    ComnetWebsocket.Repo.get_by!(
      ComnetWebsocket.DeviceActivity,
      device_id: attrs.device_id,
      connection_id: attrs.connection_id
    )
    |> ComnetWebsocket.DeviceActivity.changeset(attrs)
    |> ComnetWebsocket.Repo.update()
  end
end
