defmodule ComnetWebsocket.DeviceService do
  @moduledoc """
  Service module for managing devices and device activities.

  This module handles all device-related operations including
  device registration, activity tracking, and connection management.
  """

  alias ComnetWebsocket.{Device, DeviceActivity, Repo}

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
    Repo.get_by!(
      DeviceActivity,
      device_id: attrs.device_id,
      connection_id: attrs.connection_id
    )
    |> DeviceActivity.changeset(attrs)
    |> Repo.update()
  end
end
