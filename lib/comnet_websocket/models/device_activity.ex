defmodule ComnetWebsocket.Models.DeviceActivity do
  @moduledoc """
  Schema for device activities.

  Tracks individual connection sessions for devices, including
  when they connect and disconnect.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: UUIDv7.t() | nil,
          device_id: String.t() | nil,
          ip_address: String.t() | nil,
          connection_id: Ecto.UUID.t() | nil,
          user_id: String.t() | nil,
          version: String.t() | nil,
          started_at: DateTime.t() | nil,
          ended_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "device_activities" do
    field :device_id, :string
    field :ip_address, :string
    field :connection_id, Ecto.UUID
    field :user_id, :string
    field :version, :string
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for device activity.

  ## Parameters
  - `device_activity` - The device activity struct
  - `attrs` - The attributes to change

  ## Returns
  - A changeset
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(device_activity, attrs) do
    device_activity
    |> cast(attrs, [
      :device_id,
      :ip_address,
      :connection_id,
      :user_id,
      :version,
      :started_at,
      :ended_at
    ])
    |> validate_required([:device_id, :connection_id, :started_at])
  end
end
