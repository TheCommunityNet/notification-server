defmodule ComnetWebsocket.DeviceActivity do
  @moduledoc """
  Schema for device activities.

  Tracks individual connection sessions for devices, including
  when they connect and disconnect.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          device_id: String.t() | nil,
          connection_id: Ecto.UUID.t() | nil,
          started_at: DateTime.t() | nil,
          ended_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "device_activities" do
    field :device_id, :string
    field :connection_id, Ecto.UUID
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
    |> cast(attrs, [:device_id, :connection_id, :started_at, :ended_at])
    |> validate_required([:device_id, :connection_id, :started_at])
  end
end
