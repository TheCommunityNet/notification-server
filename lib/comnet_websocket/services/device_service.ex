defmodule ComnetWebsocket.Services.DeviceService do
  @moduledoc """
  Service module for managing devices and device activities.

  This module handles all device-related operations including
  device registration, activity tracking, and connection management.
  """

  alias ComnetWebsocket.{Repo}
  alias ComnetWebsocket.Models.{Device, DeviceActivity}
  import Ecto.Query

  @type device_attrs :: %{
          optional(:device_id) => String.t(),
          optional(:last_active_at) => DateTime.t()
        }

  @type device_activity_attrs :: %{
          optional(:device_id) => String.t(),
          optional(:connection_id) => String.t(),
          optional(:user_id) => String.t(),
          optional(:version) => String.t(),
          optional(:started_at) => DateTime.t(),
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

  @type device_list_opts :: %{
          optional(:device_id) => String.t() | nil,
          optional(:user_id) => String.t() | nil,
          optional(:ip_address) => String.t() | nil,
          optional(:page) => pos_integer(),
          optional(:per_page) => pos_integer()
        }

  @doc """
  Lists devices joined with their latest device activity, with optional filters
  and pagination.

  Options (map):
    - `:device_id`  – partial match on device_id (case-insensitive)
    - `:user_id`    – partial match on the user_id from the latest activity
    - `:ip_address` – partial match on the ip_address from the latest activity
    - `:page`       – 1-based page number (default 1)
    - `:per_page`   – records per page (default 25)

  Returns a list of maps with keys:
    `id`, `device_id`, `last_active_at`, `inserted_at`,
    `ip_address`, `user_id`, `latest_started_at`
  """
  @spec list_devices(device_list_opts()) :: [map()]
  def list_devices(opts \\ %{}) do
    page = max(1, Map.get(opts, :page) || 1)
    per_page = Map.get(opts, :per_page) || 25
    offset = (page - 1) * per_page

    opts
    |> build_devices_query()
    |> order_by([d, _la], desc: d.last_active_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> select([d, la], %{
      id: d.id,
      device_id: d.device_id,
      last_active_at: d.last_active_at,
      inserted_at: d.inserted_at,
      ip_address: la.ip_address,
      user_id: la.user_id,
      latest_started_at: la.started_at
    })
    |> Repo.all()
  end

  @doc """
  Returns the total count of devices matching the given filters.

  Accepts the same filter options as `list_devices/1` (minus pagination keys).
  """
  @spec count_devices(device_list_opts()) :: non_neg_integer()
  def count_devices(opts \\ %{}) do
    opts
    |> build_devices_query()
    |> Repo.aggregate(:count)
  end

  defp build_devices_query(opts) do
    device_id_filter = opts |> Map.get(:device_id) |> nilify_blank()
    user_id_filter = opts |> Map.get(:user_id) |> nilify_blank()
    ip_filter = opts |> Map.get(:ip_address) |> nilify_blank()

    latest_activity =
      from(da in DeviceActivity,
        select: %{
          device_id: da.device_id,
          ip_address: da.ip_address,
          user_id: da.user_id,
          started_at: da.started_at,
          rn:
            fragment(
              "ROW_NUMBER() OVER (PARTITION BY ? ORDER BY ? DESC NULLS LAST)",
              da.device_id,
              da.started_at
            )
        }
      )

    from(d in Device,
      left_join: la in subquery(latest_activity),
      on: la.device_id == d.device_id and la.rn == 1
    )
    |> filter_devices_by_device_id(device_id_filter)
    |> filter_devices_by_user_id(user_id_filter)
    |> filter_devices_by_ip(ip_filter)
  end

  defp nilify_blank(nil), do: nil
  defp nilify_blank(""), do: nil
  defp nilify_blank(val), do: val

  defp filter_devices_by_device_id(query, nil), do: query

  defp filter_devices_by_device_id(query, device_id) do
    from([d, _la] in query, where: ilike(d.device_id, ^"%#{device_id}%"))
  end

  defp filter_devices_by_user_id(query, nil), do: query

  defp filter_devices_by_user_id(query, user_id) do
    from([_d, la] in query, where: ilike(la.user_id, ^"%#{user_id}%"))
  end

  defp filter_devices_by_ip(query, nil), do: query

  defp filter_devices_by_ip(query, ip_address) do
    from([_d, la] in query, where: ilike(la.ip_address, ^"%#{ip_address}%"))
  end
end
