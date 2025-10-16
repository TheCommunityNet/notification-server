defmodule ComnetWebsocket.Device do
  @moduledoc """
  Schema for devices.

  Represents a device that can connect to the WebSocket service.
  Tracks device activity and connection status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          device_id: String.t() | nil,
          last_active_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "devices" do
    field :device_id, :string
    field :last_active_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a device.

  ## Parameters
  - `device` - The device struct
  - `attrs` - The attributes to change

  ## Returns
  - A changeset
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:device_id, :last_active_at])
    |> validate_required([:device_id, :last_active_at])
    |> unique_constraint(:device_id)
  end
end
