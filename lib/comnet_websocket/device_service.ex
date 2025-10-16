defmodule ComnetWebsocket.DeviceService do
  @moduledoc """
  Service module for managing devices and device activities.

  This module handles all device-related operations including
  device registration, activity tracking, and connection management.
  """

  alias ComnetWebsocket.{Device, DeviceActivity, Repo}
  import Ecto.Query

  @type device_attrs :: %{
          optional(:device_id) => String.t(),
          optional(:last_active_at) => DateTime.t()
        }

  @type device_activity_attrs :: %{
          optional(:device_id) => String.t(),
          optional(:connection_id) => String.t(),
          optional(:started_at) => DateTime.t(),
          optional(:user_id) => String.t(),
          optional(:ended_at) => DateTime.t(),
          optional(:ip_address) => String.t()
        }

  @type device_result :: {:ok, Device.t()} | {:error, Ecto.Changeset.t()}
  @type device_activity_result :: {:ok, DeviceActivity.t()} | {:error, Ecto.Changeset.t()}
  @type device_user_map :: %{String.t() => String.t()}

  @doc """
  Saves or updates a device record.

  Creates a new device or updates the last active timestamp if the device
  already exists.

  ## Parameters
  - `attrs` - Map of device attributes

  ## Returns
  - `{:ok, device}` - Device saved successfully
  - `{:error, changeset}` - Validation failed
  """
  @spec save_device(device_attrs()) :: device_result()
  def save_device(attrs \\ %{}) do
    attrs = Map.put_new(attrs, :last_active_at, DateTime.utc_now())

    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert!(
      on_conflict: [set: [last_active_at: attrs.last_active_at]],
      conflict_target: :device_id
    )
  end

  @doc """
  Records a new device activity session.

  Creates a new device activity record to track when a device connects.

  ## Parameters
  - `attrs` - Map of device activity attributes

  ## Returns
  - `{:ok, device_activity}` - Activity recorded successfully
  - `{:error, changeset}` - Validation failed
  """
  @spec save_device_activity(device_activity_attrs()) :: device_activity_result()
  def save_device_activity(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put_new(:connection_id, Ecto.UUID.generate())
      |> Map.put_new(:started_at, DateTime.utc_now())

    %DeviceActivity{}
    |> DeviceActivity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing device activity session.

  Records when a device disconnects by updating the activity record.

  ## Parameters
  - `attrs` - Map of device activity attributes

  ## Returns
  - `{:ok, device_activity}` - Activity updated successfully
  - `{:error, changeset}` - Validation failed
  """
  @spec update_device_activity(device_activity_attrs()) :: device_activity_result()
  def update_device_activity(attrs \\ %{}) do
    case Repo.get_by(
           DeviceActivity,
           device_id: attrs.device_id,
           connection_id: attrs.connection_id
         ) do
      nil ->
        {:error, :not_found}

      device_activity ->
        device_activity
        |> DeviceActivity.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Gets user IDs for a list of device IDs from device activities.

  Queries the device_activities table to find user_id values for the given
  device_ids. Only returns device_ids that have a non-nil user_id.

  ## Parameters
  - `device_ids` - List of device IDs to look up

  ## Returns
  - Map where keys are device_ids and values are user_ids
  """
  @spec get_user_ids_by_device_ids([String.t()]) :: device_user_map()
  def get_user_ids_by_device_ids(device_ids) when is_list(device_ids) do
    from(da in DeviceActivity,
      where: da.device_id in ^device_ids and not is_nil(da.user_id),
      select: {da.device_id, da.user_id}
    )
    |> Repo.all()
    |> Map.new()
  end
end
