defmodule ComnetWebsocket.Services.NotificationService do
  @moduledoc """
  Service module for managing notifications.

  This module handles all notification-related operations including
  creation, retrieval, and tracking of notifications.
  """

  import Ecto.Query
  alias ComnetWebsocket.{Repo, Constants}
  alias ComnetWebsocket.Models.{Notification, NotificationTracking}

  @type notification_attrs :: %{
          optional(:key) => String.t(),
          optional(:type) => String.t(),
          optional(:category) => String.t(),
          optional(:payload) => map(),
          optional(:sent_count) => integer(),
          optional(:received_count) => integer(),
          optional(:expired_at) => DateTime.t(),
          optional(:is_expired) => boolean(),
          optional(:user_id) => String.t(),
          optional(:user_ids) => [String.t()],
          optional(:device_id) => String.t()
        }

  @type notification_result :: {:ok, Notification.t()} | {:error, Ecto.Changeset.t()}

  @type websocket_message :: %{
          id: String.t(),
          category: String.t(),
          data: map(),
          is_dialog: boolean()
        }

  @doc """
  Retrieves notifications for a specific device.

  Returns all non-expired device notifications that haven't been received
  by the specified device.

  ## Parameters
  - `device_id` - The device identifier

  ## Returns
  - List of notifications for the device
  """
  @spec get_notifications_for_device(String.t()) :: [Notification.t()]
  def get_notifications_for_device(device_id) do
    now = DateTime.utc_now()

    # Get notifications that either:
    # 1. Have no tracking record for this device (broadcast to all devices)
    # 2. Have a tracking record for this device that is unread
    query =
      from n in Notification,
        left_join: nt in NotificationTracking,
        on: nt.notification_key == n.key and nt.device_id == ^device_id,
        where: n.type == ^Constants.notification_type_device(),
        where: is_nil(nt.id) or is_nil(nt.is_received) or not nt.is_received,
        where: not n.is_expired,
        where: n.expired_at > ^now,
        distinct: true

    Repo.all(query)
  end

  @doc """
  Retrieves unread notifications for a device and marks them as read.

  Returns all non-expired device notifications that haven't been received
  by the specified device, then marks them as read.

  ## Parameters
  - `device_id` - The device identifier

  ## Returns
  - List of notifications that were marked as read
  """
  @spec get_and_mark_notifications_as_read_for_device(String.t()) :: [Notification.t()]
  def get_and_mark_notifications_as_read_for_device(device_id) do
    # Get unread notifications for the device
    notifications = get_notifications_for_device(device_id)

    # Mark them as read
    received_at = DateTime.utc_now()

    Enum.each(notifications, fn notification ->
      save_notification_tracking(%{
        notification_key: notification.key,
        device_id: device_id,
        received_at: received_at,
        is_received: true
      })
    end)

    notifications
  end

  @doc """
  Retrieves notifications by group_key.

  ## Parameters
  - `group_key` - The group key to search for

  ## Returns
  - List of notifications with the specified group_key
  """
  @spec get_notification_by_group_key(String.t()) :: [Notification.t()]
  def get_notification_by_group_key(group_key) do
    Repo.all_by(Notification, group_key: group_key)
  end

  @doc """
  Retrieves a notification by its key.

  ## Parameters
  - `key` - The notification key

  ## Returns
  - The notification or nil if not found
  """
  @spec get_notification_by_key(String.t()) :: Notification.t() | nil
  def get_notification_by_key(key) do
    Repo.get_by(Notification, key: key)
  end

  @doc """
  Updates multiple notifications with the same group_key.

  ## Parameters
  - `notification_keys` - List of notification keys to update
  - `group_key` - The group key to assign to all notifications

  ## Returns
  - `{count, nil}` - Number of notifications updated
  """
  @spec update_notifications_group_key([String.t()], String.t()) :: {integer(), nil}
  def update_notifications_group_key(notification_keys, group_key) do
    query = from n in Notification, where: n.key in ^notification_keys

    Repo.update_all(query, set: [group_key: group_key])
  end

  @doc """
  Retrieves notifications for a specific user.

  Returns all non-expired user notifications that haven't been received
  by the specified user.

  ## Parameters
  - `user_id` - The user identifier

  ## Returns
  - List of notifications for the user
  """
  @spec get_notifications_for_user(String.t()) :: [Notification.t()]
  def get_notifications_for_user(user_id) do
    query =
      from n in Notification,
        left_join: nt in NotificationTracking,
        on: nt.notification_key == n.key,
        where: nt.user_id == ^user_id,
        where: n.type == ^Constants.notification_type_user(),
        where: not nt.is_received and not n.is_expired and n.expired_at > ^DateTime.utc_now()

    Repo.all(query)
  end

  @doc """
  Creates a new notification with tracking records.

  ## Parameters
  - `attrs` - Map of notification attributes

  ## Returns
  - `{:ok, notification}` - Notification created successfully
  - `{:error, changeset}` - Validation failed
  """
  @spec save_notification(notification_attrs()) :: notification_result()
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

  @doc """
  Marks expired notifications as expired.

  Updates all notifications that have passed their expiration time.

  ## Returns
  - `{count, nil}` - Number of notifications updated
  """
  @spec update_expired_notifications :: {integer(), nil}
  def update_expired_notifications do
    query =
      from n in Notification,
        where: not n.is_expired,
        where: n.expired_at < ^DateTime.utc_now()

    Repo.update_all(query, set: [is_expired: true])
  end

  @doc """
  Saves notification tracking information.

  Creates or updates tracking information for a notification.

  ## Parameters
  - `attrs` - Map of tracking attributes

  ## Returns
  - `{:ok, tracking}` - Tracking record saved successfully
  - `{:error, changeset}` - Validation failed
  """
  @spec save_notification_tracking(map()) ::
          {:ok, NotificationTracking.t()} | {:error, Ecto.Changeset.t()}
  def save_notification_tracking(attrs \\ %{}) do
    attrs
    |> find_existing_tracking()
    |> upsert_tracking(attrs)
  end

  # Private functions

  @spec create_notification(map()) :: notification_result()
  defp create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_tracking_records(String.t(), map()) :: :ok
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

  defp create_tracking_records(notification_key, %{device_id: device_id}) do
    save_notification_tracking(%{notification_key: notification_key, device_id: device_id})
    :ok
  end

  defp create_tracking_records(_notification_key, _attrs), do: :ok

  @spec find_existing_tracking(map()) :: NotificationTracking.t() | nil
  # Prefer device tracking when both device_id and user_id are present
  defp find_existing_tracking(%{notification_key: notification_key} = attrs) do
    device_id = Map.get(attrs, :device_id) || Map.get(attrs, "device_id")
    user_id = Map.get(attrs, :user_id) || Map.get(attrs, "user_id")

    user_id_filter =
      if not is_nil(user_id) do
        dynamic([nt], nt.user_id == ^user_id or is_nil(nt.user_id))
      else
        true
      end

    device_id_filter =
      if not is_nil(device_id) do
        dynamic([nt], nt.device_id == ^device_id or is_nil(nt.device_id))
      else
        true
      end

    query =
      NotificationTracking
      |> where([nt], nt.notification_key == ^notification_key)
      |> where(^device_id_filter)
      |> where(^user_id_filter)
      |> limit(1)

    Repo.one(query)
  end

  defp find_existing_tracking(_attrs), do: nil

  @spec upsert_tracking(NotificationTracking.t() | nil, map()) ::
          {:ok, NotificationTracking.t()} | {:error, Ecto.Changeset.t()}
  defp upsert_tracking(nil, attrs) do
    %NotificationTracking{}
    |> NotificationTracking.changeset(attrs)
    |> Repo.insert()
  end

  defp upsert_tracking(existing_tracking, attrs) do
    existing_tracking
    |> NotificationTracking.changeset(attrs)
    |> Repo.update()
  end

  @spec build_websocket_message(Notification.t()) :: websocket_message()
  def build_websocket_message(notification) do
    %{
      id: notification.key,
      category: notification.category,
      data: notification.payload,
      is_dialog: notification.category == Constants.notification_category_emergency()
    }
  end

  @spec build_group_websocket_message(String.t(), [Notification.t()]) :: websocket_message()
  def build_group_websocket_message(group_key, notifications) do
    [first_notification | _] = notifications

    %{
      id: group_key,
      category: first_notification.category,
      data: first_notification.payload,
      is_dialog: false
    }
  end
end
