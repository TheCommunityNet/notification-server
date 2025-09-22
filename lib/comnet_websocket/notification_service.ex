defmodule ComnetWebsocket.NotificationService do
  @moduledoc """
  Service module for managing notifications.

  This module handles all notification-related operations including
  creation, retrieval, and tracking of notifications.
  """

  import Ecto.Query, only: [from: 2]
  alias ComnetWebsocket.{Notification, NotificationTracking, Repo, Constants}

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
          optional(:user_ids) => [String.t()]
        }

  @type notification_result :: {:ok, Notification.t()} | {:error, Ecto.Changeset.t()}

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
    query =
      from n in Notification,
        left_join: nt in NotificationTracking,
        on: nt.notification_key == n.key and nt.device_id == ^device_id,
        where: n.type == ^Constants.notification_type_device(),
        where: is_nil(nt.is_received) and not n.is_expired and n.expired_at > ^DateTime.utc_now()

    Repo.all(query)
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

  defp create_tracking_records(_notification_key, _attrs), do: :ok

  @spec find_existing_tracking(map()) :: NotificationTracking.t() | nil
  defp find_existing_tracking(%{user_id: user_id, notification_key: notification_key})
       when not is_nil(user_id) do
    Repo.get_by(NotificationTracking,
      notification_key: notification_key,
      user_id: user_id
    )
  end

  defp find_existing_tracking(%{device_id: device_id, notification_key: notification_key})
       when not is_nil(device_id) do
    Repo.get_by(NotificationTracking,
      notification_key: notification_key,
      device_id: device_id
    )
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
end
